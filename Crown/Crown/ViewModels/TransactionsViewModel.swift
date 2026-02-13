import Foundation
import Observation

/// ViewModel for the Transactions tab.
///
/// Responsibilities:
/// - Loads all transactions from the repository on appear
/// - Filters transactions by search text, category, and account
/// - Groups filtered results by date for section-header display
/// - Provides mutation methods to update transaction fields (category, notes)
///
/// Future extensions:
/// - Add date-range filter support
/// - Add tags filter
/// - Support bulk-edit operations
@Observable
final class TransactionsViewModel {

    // MARK: - Dependencies
    private let transactionRepo: any TransactionRepositoryProtocol

    // MARK: - Published State
    var allTransactions: [Transaction] = []
    var searchText: String = ""
    var selectedCategory: TransactionCategory? = nil
    var selectedAccount: Account? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Computed: Filtered list

    /// Returns transactions matching all active filters.
    var filteredTransactions: [Transaction] {
        allTransactions.filter { txn in
            let matchesSearch = searchText.isEmpty ||
                txn.merchant.localizedCaseInsensitiveContains(searchText) ||
                txn.notes.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == nil || txn.category == selectedCategory

            let matchesAccount = selectedAccount == nil || txn.account?.id == selectedAccount?.id

            return matchesSearch && matchesCategory && matchesAccount
        }
    }

    /// Groups `filteredTransactions` by calendar date, newest first.
    /// Returns an array of `(dateString, [Transaction])` tuples for List sections.
    var groupedByDate: [(dateLabel: String, transactions: [Transaction])] {
        // Group by ISO date string for consistent bucketing
        let grouped = Dictionary(grouping: filteredTransactions) { txn -> String in
            txn.date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
        }
        // Sort groups descending by actual date (use first transaction's date as key)
        return grouped
            .compactMap { (key, transactions) -> (String, Date, [Transaction])? in
                guard let first = transactions.first else { return nil }
                return (key, first.date, transactions.sorted { $0.date > $1.date })
            }
            .sorted { $0.1 > $1.1 }
            .map { (dateLabel: Self.sectionLabel(for: $0.0), transactions: $0.2) }
    }

    var hasActiveFilters: Bool {
        selectedCategory != nil || selectedAccount != nil
    }

    // MARK: - Init

    init(transactionRepo: any TransactionRepositoryProtocol) {
        self.transactionRepo = transactionRepo
    }

    // MARK: - Data Loading

    func loadTransactions() {
        isLoading = true
        allTransactions = transactionRepo.fetchAll(limit: nil)
        isLoading = false
    }

    func refresh() {
        loadTransactions()
    }

    // MARK: - Mutations

    /// Updates the category and notes of a transaction and persists the change.
    func updateTransaction(
        _ transaction: Transaction,
        category: TransactionCategory,
        notes: String
    ) {
        transaction.category = category
        transaction.notes    = notes
        transactionRepo.save()
    }

    /// Removes all active filters.
    func clearFilters() {
        selectedCategory = nil
        selectedAccount  = nil
    }

    // MARK: - Helpers

    /// Converts an ISO date string into a human-readable section header.
    /// Shows "Today", "Yesterday", or a formatted date string.
    private static func sectionLabel(for isoDate: String) -> String {
        // Re-parse using the same format we grouped by
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        guard let date = formatter.date(from: isoDate) else { return isoDate }

        if Calendar.current.isDateInToday(date)     { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}
