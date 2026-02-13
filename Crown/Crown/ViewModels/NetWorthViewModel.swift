import Foundation
import Observation

/// ViewModel for the Net Worth tab.
///
/// Loads historical snapshots and current account balances to populate:
/// - The large net worth number and month-over-month trend
/// - The 12-month line chart
/// - The assets vs. liabilities breakdown list
///
/// Future extensions:
/// - Filter chart by account type (cash, investments, credit, loans)
/// - Privacy mode (blur/hide amounts for screenshots)
/// - Custom date ranges beyond 12 months
@Observable
final class NetWorthViewModel {

    // MARK: - Dependencies
    private let accountRepo:   any AccountRepositoryProtocol
    private let netWorthRepo:  any NetWorthRepositoryProtocol

    // MARK: - State
    var snapshots: [NetWorthSnapshot] = []
    var accounts: [Account] = []
    var isLoading: Bool = false

    // MARK: - Computed

    var assetAccounts: [Account] {
        accounts.filter { $0.type.isAsset }
    }

    var liabilityAccounts: [Account] {
        accounts.filter { !$0.type.isAsset }
    }

    var totalAssets: Double {
        assetAccounts.reduce(0) { $0 + $1.balance }
    }

    var totalLiabilities: Double {
        liabilityAccounts.reduce(0) { $0 + abs($1.balance) }
    }

    var currentNetWorth: Double {
        totalAssets - totalLiabilities
    }

    var previousMonthNetWorth: Double? {
        guard snapshots.count >= 2 else { return nil }
        return snapshots[snapshots.count - 2].netWorth
    }

    var netWorthChange: Double {
        guard let prev = previousMonthNetWorth else { return 0 }
        return currentNetWorth - prev
    }

    var netWorthChangePercent: Double {
        guard let prev = previousMonthNetWorth, prev != 0 else { return 0 }
        return (netWorthChange / abs(prev)) * 100
    }

    // MARK: - Init

    init(
        accountRepo:  any AccountRepositoryProtocol,
        netWorthRepo: any NetWorthRepositoryProtocol
    ) {
        self.accountRepo  = accountRepo
        self.netWorthRepo = netWorthRepo
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true
        accounts  = accountRepo.fetchVisible()
        snapshots = netWorthRepo.fetchForPastMonths(13)  // extra month for trend calc
        isLoading = false
    }

    func refresh() { loadData() }
}
