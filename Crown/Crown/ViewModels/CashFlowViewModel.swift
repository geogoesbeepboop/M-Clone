import Foundation
import Observation

/// ViewModel for the Cash Flow tab — monthly income vs expenses summary,
/// 6-month trend chart, and per-month breakdown table.
@Observable
final class CashFlowViewModel {

    // MARK: - Dependencies

    private let transactionRepo: any TransactionRepositoryProtocol

    // MARK: - State

    var selectedMonth: Date = Date()
    var isLoading: Bool = false

    // Cached transactions (13 months for charts + navigation)
    private var allTransactions: [Transaction] = []

    // MARK: - Selected Month Computed

    private var monthTransactions: [Transaction] {
        allTransactions.filter { $0.date.isInSameMonth(as: selectedMonth) }
    }

    var monthlyIncome: Double {
        monthTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    var monthlyExpenses: Double {
        monthTransactions.filter { $0.isExpense }.reduce(0) { $0 + $1.absoluteAmount }
    }

    var netCashFlow: Double { monthlyIncome - monthlyExpenses }

    var incomeRatio: CGFloat {
        guard monthlyIncome + monthlyExpenses > 0 else { return 0.5 }
        return CGFloat(monthlyIncome / (monthlyIncome + monthlyExpenses))
    }

    // MARK: - 6-Month Chart Data

    struct MonthCashFlow: Identifiable {
        let id = UUID()
        let month: Date
        let income: Double
        let expenses: Double
        var net: Double { income - expenses }
    }

    var cashFlowByMonth: [MonthCashFlow] {
        (0..<6).reversed().compactMap { offset -> MonthCashFlow? in
            guard let month = Calendar.current.date(byAdding: .month, value: -offset, to: selectedMonth) else { return nil }
            let txns = allTransactions.filter { $0.date.isInSameMonth(as: month) }
            return MonthCashFlow(
                month: month.startOfMonth,
                income: txns.filter { $0.isIncome }.reduce(0) { $0 + $1.amount },
                expenses: txns.filter { $0.isExpense }.reduce(0) { $0 + $1.absoluteAmount }
            )
        }
    }

    // MARK: - Init

    init(transactionRepo: any TransactionRepositoryProtocol) {
        self.transactionRepo = transactionRepo
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true
        let cutoff = Calendar.current.date(byAdding: .month, value: -13, to: Date()) ?? Date()
        allTransactions = transactionRepo.fetchForDateRange(start: cutoff, end: Date())
        isLoading = false
    }

    func navigateMonth(by offset: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: selectedMonth) else { return }
        selectedMonth = newMonth
    }

    func refresh() { loadData() }
}
