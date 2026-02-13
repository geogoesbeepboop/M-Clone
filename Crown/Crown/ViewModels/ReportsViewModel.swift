import Foundation
import Observation

/// ViewModel for the Reports screens.
///
/// Provides aggregated data for three report types:
/// 1. Spending by Category — donut chart + table for a selected month or custom range
/// 2. Cash Flow — monthly income vs. expense bars for the past 6-12 months
/// 3. Monthly Comparison — compare spending between two selected months
///
/// Future extensions:
/// - Annual summary (full year rolled up)
/// - Custom date range beyond the presets
/// - Export / share capability (CSV, image)
@Observable
final class ReportsViewModel {

    // MARK: - Dependencies
    private let transactionRepo: any TransactionRepositoryProtocol

    // MARK: - State
    var selectedMonth: Date = Date()
    var compareMonth: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var isLoading: Bool = false

    // MARK: - Cached transactions (loaded once, filtered in computed props)
    private var allTransactions: [Transaction] = []

    // MARK: - Init

    init(transactionRepo: any TransactionRepositoryProtocol) {
        self.transactionRepo = transactionRepo
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true
        // Load 13 months to cover comparison and cash flow charts
        let cutoff = Calendar.current.date(byAdding: .month, value: -13, to: Date()) ?? Date()
        allTransactions = transactionRepo.fetchForDateRange(start: cutoff, end: Date())
        isLoading = false
    }

    // MARK: - Spending by Category (single month)

    struct CategorySpend: Identifiable {
        let id = UUID()
        let category: TransactionCategory
        let total: Double
        let percentage: Double
    }

    /// Returns spending totals per category for `selectedMonth`, sorted descending.
    var spendingByCategory: [CategorySpend] {
        let expenses = transactionsFor(month: selectedMonth).filter { $0.isExpense }
        let grouped = Dictionary(grouping: expenses, by: \.category)
        let totals = grouped.map { (cat, txns) in
            (cat, txns.reduce(0) { $0 + $1.absoluteAmount })
        }
        let grandTotal = totals.reduce(0) { $0 + $1.1 }
        guard grandTotal > 0 else { return [] }

        return totals
            .sorted { $0.1 > $1.1 }
            .map { cat, total in
                CategorySpend(
                    category: cat,
                    total: total,
                    percentage: (total / grandTotal) * 100
                )
            }
    }

    // MARK: - Cash Flow by Month (last N months)

    struct MonthCashFlow: Identifiable {
        let id = UUID()
        let month: Date
        let income: Double
        let expenses: Double
        var net: Double { income - expenses }
    }

    /// Returns income and expenses per month for the past 6 months.
    var cashFlowByMonth: [MonthCashFlow] {
        (0..<6).reversed().compactMap { offset -> MonthCashFlow? in
            guard let month = Calendar.current.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let txns = transactionsFor(month: month)
            return MonthCashFlow(
                month: month.startOfMonth,
                income: txns.filter { $0.isIncome }.reduce(0) { $0 + $1.amount },
                expenses: txns.filter { $0.isExpense }.reduce(0) { $0 + $1.absoluteAmount }
            )
        }
    }

    // MARK: - Monthly Comparison

    struct ComparisonRow: Identifiable {
        let id = UUID()
        let category: TransactionCategory
        let primaryTotal: Double
        let compareTotal: Double
        var difference: Double { primaryTotal - compareTotal }
    }

    /// Compares category spending between `selectedMonth` and `compareMonth`.
    var monthlyComparison: [ComparisonRow] {
        let primaryTxns = transactionsFor(month: selectedMonth).filter { $0.isExpense }
        let compareTxns = transactionsFor(month: compareMonth).filter { $0.isExpense }

        let primaryMap = Dictionary(grouping: primaryTxns, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.absoluteAmount } }
        let compareMap = Dictionary(grouping: compareTxns, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.absoluteAmount } }

        let allCategories = Set(primaryMap.keys).union(Set(compareMap.keys))
        return allCategories
            .map { cat in
                ComparisonRow(
                    category: cat,
                    primaryTotal: primaryMap[cat] ?? 0,
                    compareTotal: compareMap[cat] ?? 0
                )
            }
            .sorted { $0.primaryTotal > $1.primaryTotal }
    }

    // MARK: - Helpers

    private func transactionsFor(month: Date) -> [Transaction] {
        allTransactions.filter { $0.date.isInSameMonth(as: month) }
    }
}
