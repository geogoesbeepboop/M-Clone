import Foundation
import Observation

@Observable
final class DashboardViewModel {

    // MARK: - Dependencies
    private let accountRepo: any AccountRepositoryProtocol
    private let transactionRepo: any TransactionRepositoryProtocol
    private let netWorthRepo: any NetWorthRepositoryProtocol

    // MARK: - State
    var accounts: [Account] = []
    var currentMonthTransactions: [Transaction] = []
    var pendingTransactions: [Transaction] = []
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
        pendingTransactions = transactionRepo.fetchPending()
        recentSnapshots = netWorthRepo.fetchForPastMonths(12)
    }

    func refresh() {
        loadData()
    }
}
