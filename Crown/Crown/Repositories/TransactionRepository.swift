import Foundation
import SwiftData

// MARK: - Protocol

protocol TransactionRepositoryProtocol {
    func fetchAll(limit: Int?) -> [Transaction]
    func fetchForMonth(month: Int, year: Int) -> [Transaction]
    func fetchForDateRange(start: Date, end: Date) -> [Transaction]
    func fetchForAccount(_ account: Account) -> [Transaction]
    func fetchForCategory(_ category: TransactionCategory, month: Int, year: Int) -> [Transaction]
    func fetchPending() -> [Transaction]
    func fetchByPlaidTransactionId(_ plaidId: String) -> Transaction?
    func insert(_ transaction: Transaction)
    func delete(_ transaction: Transaction)
    func save()
}

// MARK: - SwiftData Implementation

final class TransactionRepository: TransactionRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll(limit: Int? = nil) -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        let filtered = filterByDataMode(all)
        if let limit {
            return Array(filtered.prefix(limit))
        }
        return filtered
    }

    func fetchForMonth(month: Int, year: Int) -> [Transaction] {
        let calendar = Calendar.current
        guard
            let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
            let end   = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)
        else { return [] }
        return fetchForDateRange(start: start, end: end)
    }

    func fetchForDateRange(start: Date, end: Date) -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return filterByDataMode(results)
    }

    func fetchForAccount(_ account: Account) -> [Transaction] {
        let results = account.transactions.sorted { $0.date > $1.date }
        return filterByDataMode(results)
    }

    func fetchForCategory(_ category: TransactionCategory, month: Int, year: Int) -> [Transaction] {
        fetchForMonth(month: month, year: year)
            .filter { $0.category == category }
    }

    func fetchPending() -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.isPending == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return filterByDataMode(results)
    }

    /// Filters transactions based on the current data mode setting.
    /// - Mock ON: show only mock transactions (no plaidTransactionId)
    /// - Mock OFF: show only Plaid transactions; fall back to all if none exist
    private func filterByDataMode(_ transactions: [Transaction]) -> [Transaction] {
        if AppConfig.useMockData {
            return transactions.filter { $0.plaidTransactionId == nil }
        } else {
            let plaid = transactions.filter { $0.plaidTransactionId != nil }
            return plaid.isEmpty ? transactions : plaid
        }
    }

    func fetchByPlaidTransactionId(_ plaidId: String) -> Transaction? {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.plaidTransactionId == plaidId }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func insert(_ transaction: Transaction) {
        modelContext.insert(transaction)
    }

    func delete(_ transaction: Transaction) {
        modelContext.delete(transaction)
    }

    func save() {
        try? modelContext.save()
    }
}
