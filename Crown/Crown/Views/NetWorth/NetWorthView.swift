import SwiftUI

/// Net Worth tab — shows current net worth, a 12-month trend chart,
/// and a breakdown of assets and liabilities by account.
///
/// Data flow: NetWorthViewModel loads accounts + snapshots,
/// which this view renders via NetWorthChartView and AssetsLiabilitiesListView.
struct NetWorthView: View {
    @Environment(\.accountRepository)   private var accountRepo
    @Environment(\.netWorthRepository)  private var netWorthRepo

    @State private var viewModel: NetWorthViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Net Worth")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if viewModel == nil {
                let vm = NetWorthViewModel(accountRepo: accountRepo, netWorthRepo: netWorthRepo)
                viewModel = vm
                vm.loadData()
            }
        }
    }

    @ViewBuilder
    private func content(vm: NetWorthViewModel) -> some View {
        ScrollView {
            VStack(spacing: CrownTheme.sectionSpacing) {
                // Hero net worth card
                heroCard(vm: vm)

                // 12-month line chart
                if !vm.snapshots.isEmpty {
                    NetWorthChartView(snapshots: vm.snapshots)
                }

                // Assets section
                if !vm.assetAccounts.isEmpty {
                    AssetsLiabilitiesListView(
                        title: "Assets",
                        accounts: vm.assetAccounts,
                        total: vm.totalAssets,
                        isLiability: false
                    )
                }

                // Liabilities section
                if !vm.liabilityAccounts.isEmpty {
                    AssetsLiabilitiesListView(
                        title: "Liabilities",
                        accounts: vm.liabilityAccounts,
                        total: vm.totalLiabilities,
                        isLiability: true
                    )
                }
            }
            .padding(.horizontal, CrownTheme.horizontalPadding)
            .padding(.bottom, CrownTheme.sectionSpacing)
        }
        .background(CrownTheme.screenBackground)
        .refreshable { vm.refresh() }
    }

    // MARK: - Hero Card

    private func heroCard(vm: NetWorthViewModel) -> some View {
        VStack(spacing: 8) {
            Text("Total Net Worth")
                .font(CrownTheme.captionFont)
                .foregroundStyle(.secondary)

            CurrencyText(amount: vm.currentNetWorth, font: CrownTheme.largeCurrencyFont)

            // Month-over-month trend
            let change = vm.netWorthChange
            let percent = vm.netWorthChangePercent
            if change != 0 {
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                    CurrencyText(amount: abs(change), font: CrownTheme.captionFont, showAbsoluteValue: true)
                    Text(String(format: "(%.1f%%)", abs(percent)))
                        .font(CrownTheme.captionFont)
                    Text("vs last month")
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(change >= 0 ? CrownTheme.income : CrownTheme.expense)
            }

            Divider()

            // Assets vs Liabilities summary
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Assets")
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(.secondary)
                    CurrencyText(amount: vm.totalAssets, font: CrownTheme.headlineFont)
                        .foregroundStyle(CrownTheme.income)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Liabilities")
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(.secondary)
                    CurrencyText(amount: vm.totalLiabilities, font: CrownTheme.headlineFont)
                        .foregroundStyle(CrownTheme.expense)
                }
            }
        }
        .crownCard()
    }
}

#Preview {
    NavigationStack { NetWorthView() }
}
