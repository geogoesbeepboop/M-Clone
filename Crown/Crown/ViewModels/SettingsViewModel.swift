import Foundation
import SwiftData
import Observation
import UIKit

/// Manages bank account connections and data sync operations.
///
/// Holds sync state (loading, error), exposes connected accounts, and
/// drives the Plaid Link flow by creating a link token on demand.
@Observable
final class SettingsViewModel {

    // MARK: - Published State

    var connectedAccounts: [Account]  = []
    var isSyncing: Bool               = false
    var linkToken: String?            = nil    // Set before presenting Plaid Link
    var errorMessage: String?         = nil
    var successMessage: String?       = nil
    var isConnectingAccount: Bool     = false  // Controls Plaid Link presentation

    /// Mirrors AppConfig.useMockData so the Settings toggle is reactive.
    var useMockData: Bool {
        get { AppConfig.useMockData }
        set { AppConfig.useMockData = newValue }
    }

    /// Mirrors AppConfig.appearanceMode for the Settings picker.
    var appearanceMode: String {
        get { AppConfig.appearanceMode }
        set { AppConfig.appearanceMode = newValue }
    }

    // MARK: - Private

    private let accountRepo:     AccountRepositoryProtocol
    private let transactionRepo: TransactionRepositoryProtocol
    private let netWorthRepo:    NetWorthRepositoryProtocol
    private let modelContext:    ModelContext
    private let plaidService:    PlaidServiceProtocol
    private let syncService:     DataSyncService

    // MARK: - Init

    init(
        accountRepo:     AccountRepositoryProtocol,
        transactionRepo: TransactionRepositoryProtocol,
        netWorthRepo:    NetWorthRepositoryProtocol,
        modelContext:    ModelContext,
        plaidService:    PlaidServiceProtocol = PlaidService()
    ) {
        self.accountRepo     = accountRepo
        self.transactionRepo = transactionRepo
        self.netWorthRepo    = netWorthRepo
        self.modelContext    = modelContext
        self.plaidService    = plaidService
        self.syncService     = DataSyncService(
            plaidService:    plaidService,
            accountRepo:     accountRepo,
            transactionRepo: transactionRepo,
            netWorthRepo:    netWorthRepo,
            modelContext:    modelContext
        )
    }

    // MARK: - Data Loading

    func loadData() {
        // Use fetchAll() (unfiltered) so connected accounts always appear
        // in Settings regardless of mock data toggle state
        connectedAccounts = accountRepo.fetchAll().filter { $0.plaidAccessToken != nil && !$0.isHidden }
    }

    // MARK: - Plaid Link Flow

    /// Step 1: Create a link token, then present Plaid Link UI.
    @MainActor
    func startConnectFlow() async {
        print("[Crown/Plaid] startConnectFlow() called. isConfigured=\(AppConfig.isPlaidConfigured), clientId='\(AppConfig.plaidClientId.isEmpty ? "MISSING" : "set")', secret='\(AppConfig.plaidSecret.isEmpty ? "MISSING" : "set")'")
        guard AppConfig.isPlaidConfigured else {
            errorMessage = "Plaid is not configured. Add PLAID_CLIENT_ID and PLAID_SECRET to your Xcode scheme environment variables."
            return
        }

        isSyncing   = true
        errorMessage = nil

        do {
            print("[Crown/Plaid] Calling createLinkToken()…")
            linkToken           = try await plaidService.createLinkToken()
            print("[Crown/Plaid] createLinkToken() succeeded — token prefix: \(linkToken?.prefix(20) ?? "nil")…")
            isConnectingAccount = true
        } catch {
            print("[Crown/Plaid] createLinkToken() FAILED: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isSyncing = false
    }

    /// Step 2: Called after Plaid Link succeeds with a public token.
    /// Exchanges it for an access token, then syncs accounts + transactions.
    @MainActor
    func handlePlaidSuccess(publicToken: String, metadata: [String: Any]) async {
        print("[Crown/Plaid] handlePlaidSuccess() — exchanging public token…")
        isConnectingAccount = false
        isSyncing           = true
        errorMessage        = nil

        do {
            let accessToken = try await plaidService.exchangePublicToken(publicToken)
            print("[Crown/Plaid] exchangePublicToken() succeeded. Syncing accounts…")

            // Switch to real data mode — mock data stays in DB for toggle-back,
            // repo-level filtering will show only Plaid data
            AppConfig.useMockData = false

            let accountCount = try await syncService.syncAccounts(accessToken: accessToken)
            print("[Crown/Plaid] syncAccounts() done — \(accountCount) accounts. Syncing transactions…")
            let txCount      = try await syncService.syncTransactions(accessToken: accessToken)
            print("[Crown/Plaid] syncTransactions() done — \(txCount) transactions.")
            syncService.takeNetWorthSnapshot()

            loadData()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            successMessage = "Connected! Imported \(accountCount) accounts and \(txCount) transactions."
        } catch {
            print("[Crown/Plaid] handlePlaidSuccess() FAILED: \(error.localizedDescription)")
            errorMessage = "Connection failed: \(error.localizedDescription)"
        }
        isSyncing = false
    }

    /// Sync all connected accounts to fetch latest balances and transactions.
    @MainActor
    func syncAllAccounts() async {
        let tokens = Set(connectedAccounts.compactMap { $0.plaidAccessToken })
        guard !tokens.isEmpty else {
            errorMessage = "No connected accounts to sync."
            return
        }

        isSyncing    = true
        errorMessage = nil

        do {
            for token in tokens {
                try await syncService.syncAccounts(accessToken: token)
                try await syncService.syncTransactions(accessToken: token)
            }
            syncService.takeNetWorthSnapshot()
            loadData()
            successMessage = "Sync complete."
        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
        }
        isSyncing = false
    }

    /// Seeds mock data immediately (idempotent — safe to call multiple times).
    func seedMockData() {
        MockDataService.seedIfNeeded(context: modelContext)
        successMessage = "Demo data loaded."
    }

    /// Removes a connected account (clears Plaid tokens; keeps the account record hidden).
    func disconnectAccount(_ account: Account) {
        account.plaidAccessToken = nil
        account.plaidAccountId   = nil
        account.isHidden         = true
        accountRepo.save()
        loadData()
    }
}
