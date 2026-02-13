import Foundation
import SwiftData

/// Orchestrates syncing Plaid data into local SwiftData storage.
///
/// Performs upserts keyed on Plaid's stable IDs so re-syncing is idempotent —
/// it updates existing records instead of creating duplicates.
///
/// Typical flow:
/// 1. User connects bank via Plaid Link → `ConnectAccountView` → receives access token
/// 2. Call `syncAccounts(accessToken:)` to populate/update Account records
/// 3. Call `syncTransactions(accessToken:)` to populate/update Transaction records
/// 4. Call `takeNetWorthSnapshot()` to record current totals in history
final class DataSyncService {

    private let plaidService: PlaidServiceProtocol
    private let accountRepo: AccountRepositoryProtocol
    private let transactionRepo: TransactionRepositoryProtocol
    private let netWorthRepo: NetWorthRepositoryProtocol
    private let modelContext: ModelContext

    init(
        plaidService: PlaidServiceProtocol,
        accountRepo: AccountRepositoryProtocol,
        transactionRepo: TransactionRepositoryProtocol,
        netWorthRepo: NetWorthRepositoryProtocol,
        modelContext: ModelContext
    ) {
        self.plaidService      = plaidService
        self.accountRepo       = accountRepo
        self.transactionRepo   = transactionRepo
        self.netWorthRepo      = netWorthRepo
        self.modelContext      = modelContext
    }

    // MARK: - Account Sync

    /// Fetches current balances from Plaid and upserts local Account records.
    /// Returns the number of accounts updated.
    @discardableResult
    func syncAccounts(accessToken: String) async throws -> Int {
        let plaidAccounts = try await plaidService.fetchBalances(accessToken: accessToken)

        for plaidAccount in plaidAccounts {
            let balance = plaidAccount.balances.current ?? plaidAccount.balances.available ?? 0

            if let existing = accountRepo.fetchByPlaidAccountId(plaidAccount.account_id) {
                // Update balance and sync time
                existing.balance    = accountBalance(for: plaidAccount, raw: balance)
                existing.lastSynced = Date()
            } else {
                // Create new Account
                let account = Account(
                    name:          plaidAccount.official_name ?? plaidAccount.name,
                    institution:   "Connected Bank",
                    type:          accountType(from: plaidAccount),
                    balance:       accountBalance(for: plaidAccount, raw: balance),
                    plaidAccountId: plaidAccount.account_id,
                    plaidAccessToken: accessToken
                )
                account.lastSynced = Date()
                accountRepo.insert(account)
            }
        }
        accountRepo.save()
        return plaidAccounts.count
    }

    // MARK: - Transaction Sync

    /// Pages through Plaid's /transactions/sync endpoint and upserts Transaction records.
    /// Returns the number of new transactions added.
    @discardableResult
    func syncTransactions(accessToken: String) async throws -> Int {
        var cursor: String? = nil
        var addedCount = 0
        var hasMore = true

        while hasMore {
            let response = try await plaidService.fetchTransactions(
                accessToken: accessToken,
                cursor: cursor
            )

            // Handle removals
            for removed in response.removed {
                if let tx = transactionRepo.fetchByPlaidTransactionId(removed.transaction_id) {
                    modelContext.delete(tx)
                }
            }

            // Handle additions + modifications (same upsert logic)
            for plaidTx in response.added + response.modified {
                upsertTransaction(plaidTx, accessToken: accessToken)
                addedCount += 1
            }

            cursor  = response.next_cursor
            hasMore = response.has_more
        }

        try? modelContext.save()
        return addedCount
    }

    // MARK: - Net Worth Snapshot

    /// Computes current totals from all visible accounts and inserts a NetWorthSnapshot.
    func takeNetWorthSnapshot() {
        let accounts = accountRepo.fetchVisible()
        let assets      = accounts.filter { $0.type.isAsset }.reduce(0) { $0 + $1.balance }
        let liabilities = accounts.filter { !$0.type.isAsset }.reduce(0) { $0 + abs($1.balance) }

        let snapshot = NetWorthSnapshot(
            date:             Date(),
            totalAssets:      assets,
            totalLiabilities: liabilities
        )
        netWorthRepo.insert(snapshot)
        netWorthRepo.save()
    }

    // MARK: - Private Helpers

    private func upsertTransaction(_ plaidTx: PlaidTransaction, accessToken: String) {
        // Find matching account by plaid account_id
        let account = accountRepo.fetchByPlaidAccountId(plaidTx.account_id)

        // Plaid: positive = debit (expense). Our convention: negative = expense, positive = income.
        let localAmount = -plaidTx.amount

        let category   = mapCategory(plaidTx.personal_finance_category?.primary)
        let merchant   = plaidTx.merchant_name ?? plaidTx.name
        let date       = parsePlaidDate(plaidTx.date) ?? Date()

        if let existing = transactionRepo.fetchByPlaidTransactionId(plaidTx.transaction_id) {
            // Update mutable fields
            existing.amount    = localAmount
            existing.merchant  = merchant
            existing.isPending = plaidTx.pending
            existing.date      = date
            // Don't override user-edited category
        } else {
            let tx = Transaction(
                date:               date,
                merchant:           merchant,
                amount:             localAmount,
                category:           category,
                isPending:          plaidTx.pending,
                plaidTransactionId: plaidTx.transaction_id
            )
            tx.account = account
            modelContext.insert(tx)
        }
    }

    /// Converts Plaid's account type/subtype to our AccountType enum.
    private func accountType(from plaidAccount: PlaidAccount) -> AccountType {
        switch plaidAccount.type.lowercased() {
        case "depository":
            if plaidAccount.subtype?.lowercased() == "savings" { return .savings }
            return .checking
        case "credit":
            return .creditCard
        case "investment", "brokerage":
            return .investment
        case "loan":
            if plaidAccount.subtype?.lowercased().contains("mortgage") == true { return .mortgage }
            return .loan
        default:
            return .other
        }
    }

    /// Returns the correct signed balance.
    /// Credit cards and loans show a positive Plaid balance = amount owed (liability → store as negative).
    private func accountBalance(for plaidAccount: PlaidAccount, raw: Double) -> Double {
        switch plaidAccount.type.lowercased() {
        case "credit", "loan":
            return -abs(raw)   // Liabilities are negative in our model
        default:
            return raw
        }
    }

    /// Maps Plaid's personal_finance_category.primary to our TransactionCategory.
    private func mapCategory(_ primary: String?) -> TransactionCategory {
        switch primary?.uppercased() {
        case "FOOD_AND_DRINK":         return .dining
        case "GROCERIES":              return .groceries
        case "TRANSPORTATION":         return .transportation
        case "TRAVEL":                 return .travel
        case "ENTERTAINMENT":          return .entertainment
        case "GENERAL_MERCHANDISE",
             "CLOTHING_AND_ACCESSORIES",
             "ELECTRONICS":            return .shopping
        case "UTILITIES":              return .utilities
        case "HOME_IMPROVEMENT",
             "RENT_AND_UTILITIES",
             "RENT":                   return .housing
        case "MEDICAL":                return .healthcare
        case "PERSONAL_CARE":          return .personalCare
        case "EDUCATION":              return .education
        case "SUBSCRIPTION":           return .subscriptions
        case "INCOME":                 return .income
        case "TRANSFER_IN",
             "TRANSFER_OUT",
             "TRANSFER":               return .transfer
        case "BANK_FEES",
             "SERVICE",
             "FEES_AND_ADJUSTMENTS":   return .fees
        default:                        return .other
        }
    }

    private func parsePlaidDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: string)
    }
}
