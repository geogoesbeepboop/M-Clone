import Foundation
import Observation

struct DailySpending: Identifiable {
    let id = UUID()
    let dayOfMonth: Int
    let cumulativeAmount: Double
    let label: String  // "This month" or "Last month"
}

@Observable
final class DashboardViewModel {

    // MARK: - Dependencies
    private let accountRepo: any AccountRepositoryProtocol
    private let transactionRepo: any TransactionRepositoryProtocol
    private let netWorthRepo: any NetWorthRepositoryProtocol

    // MARK: - State
    var accounts: [Account] = []
    var currentMonthTransactions: [Transaction] = []
    var lastMonthTransactions: [Transaction] = []
    var pendingTransactions: [Transaction] = []
    var recentTransactions: [Transaction] = []
    var recentSnapshots: [NetWorthSnapshot] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Computed Aggregates

    var totalNetWorth: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var totalAssets: Double {
        accounts.filter { $0.type.isAsset }.reduce(0) { $0 + $1.balance }
    }

    var totalLiabilities: Double {
        accounts.filter { !$0.type.isAsset }.reduce(0) { $0 + abs($1.balance) }
    }

    var monthlyIncome: Double {
        currentMonthTransactions
            .filter { $0.isIncome }
            .reduce(0) { $0 + $1.amount }
    }

    var monthlyExpenses: Double {
        currentMonthTransactions
            .filter { $0.isExpense }
            .reduce(0) { $0 + abs($1.amount) }
    }

    var netCashFlow: Double { monthlyIncome - monthlyExpenses }

    var topSpendingCategories: [(category: TransactionCategory, total: Double)] {
        let expenses = currentMonthTransactions.filter { $0.isExpense }
        let grouped = Dictionary(grouping: expenses, by: \.category)
        return grouped
            .map { (category: $0.key, total: $0.value.reduce(0) { $0 + abs($1.amount) }) }
            .sorted { $0.total > $1.total }
            .prefix(5)
            .map { $0 }
    }

    var thisMonthTotal: Double {
        currentMonthTransactions.filter { $0.isExpense }.reduce(0.0) { $0 + abs($1.amount) }
    }

    var lastMonthTotal: Double {
        lastMonthTransactions.filter { $0.isExpense }.reduce(0.0) { $0 + abs($1.amount) }
    }

    var cumulativeSpendingData: [DailySpending] {
        let cal = Calendar.current
        let today = Date()
        let dayOfMonth = cal.component(.day, from: today)

        // This month — cumulate expenses by day
        var thisMonthPoints: [DailySpending] = []
        var runningTotal = 0.0
        for day in 1...dayOfMonth {
            let dayExpenses = currentMonthTransactions
                .filter { $0.isExpense && cal.component(.day, from: $0.date) == day }
                .reduce(0.0) { $0 + abs($1.amount) }
            runningTotal += dayExpenses
            thisMonthPoints.append(DailySpending(dayOfMonth: day, cumulativeAmount: runningTotal, label: "This month"))
        }

        // Last month — cumulate full month
        let lastMonthDays = cal.range(of: .day, in: .month, for: today.monthOffset(by: -1))?.count ?? 30
        var lastMonthPoints: [DailySpending] = []
        runningTotal = 0.0
        for day in 1...lastMonthDays {
            let dayExpenses = lastMonthTransactions
                .filter { $0.isExpense && cal.component(.day, from: $0.date) == day }
                .reduce(0.0) { $0 + abs($1.amount) }
            runningTotal += dayExpenses
            lastMonthPoints.append(DailySpending(dayOfMonth: day, cumulativeAmount: runningTotal, label: "Last month"))
        }

        return thisMonthPoints + lastMonthPoints
    }

    var netWorthChange: Double {
        guard recentSnapshots.count >= 2 else { return 0 }
        let previous = recentSnapshots[recentSnapshots.count - 2].netWorth
        let current = recentSnapshots.last?.netWorth ?? totalNetWorth
        return current - previous
    }

    var netWorthChangePercent: Double {
        guard recentSnapshots.count >= 2 else { return 0 }
        let previous = recentSnapshots[recentSnapshots.count - 2].netWorth
        guard previous != 0 else { return 0 }
        return (netWorthChange / abs(previous)) * 100
    }

    // MARK: - Init

    init(
        accountRepo: any AccountRepositoryProtocol,
        transactionRepo: any TransactionRepositoryProtocol,
        netWorthRepo: any NetWorthRepositoryProtocol
    ) {
        self.accountRepo = accountRepo
        self.transactionRepo = transactionRepo
        self.netWorthRepo = netWorthRepo
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true
        defer { isLoading = false }

        accounts = accountRepo.fetchVisible()

        let now = Date()
        currentMonthTransactions = transactionRepo.fetchForMonth(
            month: now.month, year: now.year
        )
        let lastMonth = now.monthOffset(by: -1)
        lastMonthTransactions = transactionRepo.fetchForMonth(
            month: lastMonth.month, year: lastMonth.year
        )
        pendingTransactions = transactionRepo.fetchPending()
        recentTransactions = transactionRepo.fetchAll(limit: 4)
        recentSnapshots = netWorthRepo.fetchForPastMonths(12)
    }

    func refresh() {
        loadData()
    }
}
