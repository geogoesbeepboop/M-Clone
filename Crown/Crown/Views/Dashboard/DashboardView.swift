import SwiftUI

struct DashboardView: View {
    @Environment(\.accountRepository)     private var accountRepo
    @Environment(\.transactionRepository) private var transactionRepo
    @Environment(\.netWorthRepository)    private var netWorthRepo
    @Environment(\.showChat)             private var showChat
    @Environment(\.selectedTab)          private var selectedTab

    @State private var viewModel: DashboardViewModel?
    @State private var showSettings      = false
    @State private var showReports       = false
    @State private var showNotifications = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: CrownTheme.sectionSpacing) {
                if let vm = viewModel {
                    if vm.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else {
                        // 1. Spending (cumulative line chart)
                        SpendingCardView(
                            spendingData: vm.cumulativeSpendingData,
                            thisMonthTotal: vm.thisMonthTotal,
                            lastMonthTotal: vm.lastMonthTotal
                        )

                        // 2. Net Worth — taps to Accounts tab
                        Button {
                            selectedTab.wrappedValue = .accounts
                        } label: {
                            NetWorthCardView(
                                netWorth:       vm.totalNetWorth,
                                change:         vm.netWorthChange,
                                changePercent:  vm.netWorthChangePercent,
                                snapshots:      vm.recentSnapshots
                            )
                        }
                        .buttonStyle(.plain)

                        // 3. Recent Transactions
                        RecentTransactionsCardView(
                            transactions: vm.recentTransactions
                        )

                        // 4. Recurring (empty state)
                        RecurringCardView()

                        // 5. Investments (empty state)
                        InvestmentsCardView()

                        // 6. Goals (empty state)
                        GoalsCardView()
                    }
                }
            }
            .padding(.horizontal, CrownTheme.horizontalPadding)
            .padding(.bottom, CrownTheme.sectionSpacing)
        }
        .background(CrownTheme.screenBackground)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 4) {
                    Button {
                        showReports = true
                    } label: {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .foregroundStyle(CrownTheme.primaryBlue)
                    }

                    Button {
                        showNotifications = true
                    } label: {
                        Image(systemName: "bell")
                            .foregroundStyle(CrownTheme.primaryBlue)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(CrownTheme.primaryBlue)
                    }

                    Button {
                        showChat.wrappedValue = true
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(CrownTheme.primaryBlue)
                    }
                }
            }
        }
        .refreshable {
            viewModel?.refresh()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showReports) {
            ReportsView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
        .onAppear {
            if viewModel == nil {
                let created = DashboardViewModel(
                    accountRepo: accountRepo,
                    transactionRepo: transactionRepo,
                    netWorthRepo: netWorthRepo
                )
                viewModel = created
                created.loadData()
            }
        }
    }
}

#Preview {
    NavigationStack { DashboardView() }
}
