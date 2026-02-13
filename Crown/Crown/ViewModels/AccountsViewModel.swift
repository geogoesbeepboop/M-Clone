import Foundation
import Observation

/// ViewModel for the Accounts tab — shows net worth overview with segmented
/// filtering by account category, 12-month trend chart, and grouped account lists.
@Observable
final class AccountsViewModel {

    // MARK: - Segment

    enum Segment: String, CaseIterable, Identifiable {
        case netWorth    = "Net Worth"
        case cash        = "Cash"
        case investments = "Investments"
        case credit      = "Credit"

        var id: String { rawValue }
    }

    // MARK: - Dependencies

    private let accountRepo:  any AccountRepositoryProtocol
    private let netWorthRepo: any NetWorthRepositoryProtocol

    // MARK: - State

    var selectedSegment: Segment = .netWorth
    var accounts: [Account] = []
    var snapshots: [NetWorthSnapshot] = []
    var isLoading: Bool = false

    // MARK: - Filtered Accounts

    var filteredAccounts: [Account] {
        switch selectedSegment {
        case .netWorth:    accounts
        case .cash:        accounts.filter { $0.type == .checking || $0.type == .savings }
        case .investments: accounts.filter { $0.type == .investment }
        case .credit:      accounts.filter { $0.type == .creditCard || $0.type == .loan || $0.type == .mortgage }
        }
    }

    // MARK: - Net Worth Computed

    var assetAccounts: [Account] { accounts.filter { $0.type.isAsset } }
    var liabilityAccounts: [Account] { accounts.filter { !$0.type.isAsset } }

    var totalAssets: Double { assetAccounts.reduce(0) { $0 + $1.balance } }
    var totalLiabilities: Double { liabilityAccounts.reduce(0) { $0 + abs($1.balance) } }
    var currentNetWorth: Double { totalAssets - totalLiabilities }

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

    // MARK: - Segment Totals

    var segmentTotal: Double {
        switch selectedSegment {
        case .netWorth:    currentNetWorth
        case .cash:        filteredAccounts.reduce(0) { $0 + $1.balance }
        case .investments: filteredAccounts.reduce(0) { $0 + $1.balance }
        case .credit:      filteredAccounts.reduce(0) { $0 + abs($1.balance) }
        }
    }

    /// Account groups for the current segment. Each group is (title, accounts).
    var accountGroups: [(title: String, accounts: [Account])] {
        switch selectedSegment {
        case .netWorth:
            var groups: [(String, [Account])] = []
            let cash = accounts.filter { $0.type == .checking || $0.type == .savings }
            if !cash.isEmpty { groups.append(("Cash", cash)) }
            let investments = accounts.filter { $0.type == .investment }
            if !investments.isEmpty { groups.append(("Investments", investments)) }
            let credit = accounts.filter { $0.type == .creditCard || $0.type == .loan || $0.type == .mortgage }
            if !credit.isEmpty { groups.append(("Credit", credit)) }
            let others = accounts.filter { $0.type == .other }
            if !others.isEmpty { groups.append(("Other", others)) }
            return groups
        case .cash:
            return [("Cash", filteredAccounts)]
        case .investments:
            return [("Investments", filteredAccounts)]
        case .credit:
            return [("Credit", filteredAccounts)]
        }
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
        snapshots = netWorthRepo.fetchForPastMonths(13)
        isLoading = false
    }

    func refresh() { loadData() }
}
