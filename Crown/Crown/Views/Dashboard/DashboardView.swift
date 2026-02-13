import SwiftUI

struct DashboardView: View {
    @Environment(\.accountRepository)     private var accountRepo
    @Environment(\.transactionRepository) private var transactionRepo
    @Environment(\.netWorthRepository)    private var netWorthRepo
    @Environment(\.showChat)             private var showChat
    @Environment(\.selectedTab)          private var selectedTab

    @State private var viewModel: DashboardViewModel?
    @State private var showSettings = false
    @State private var showReports  = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: CrownTheme.sectionSpacing) {
                // Greeting header
                greetingHeader

                if let vm = viewModel {
                    if vm.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else {
                        // Net Worth (compact hero) — taps to Accounts tab
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

                        // Top Spending
                        SpendingCardView(categories: vm.topSpendingCategories)

                        // Pending
                        UpcomingBillsCardView(pendingTransactions: vm.pendingTransactions)
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
                Button {
                    showReports = true
                } label: {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .foregroundStyle(CrownTheme.primaryBlue)
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

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(CrownTheme.subheadFont)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(CrownTheme.primaryBlue)
        }
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}

#Preview {
    NavigationStack { DashboardView() }
}
