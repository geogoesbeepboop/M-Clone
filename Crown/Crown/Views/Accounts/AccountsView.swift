import SwiftUI
import SwiftData
import Charts

/// Accounts tab — shows net worth overview with segmented filtering,
/// a 12-month trend chart, and grouped account lists.
struct AccountsView: View {
    @Environment(\.accountRepository)     private var accountRepo
    @Environment(\.transactionRepository) private var transactionRepo
    @Environment(\.netWorthRepository)    private var netWorthRepo
    @Environment(\.modelContext)          private var modelContext
    @Environment(\.showChat)             private var showChat

    @State private var viewModel: AccountsViewModel?
    @State private var settingsVM: SettingsViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        Task {
                            let svm = ensureSettingsVM()
                            await svm.startConnectFlow()
                        }
                    } label: {
                        Image(systemName: "plus")
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
        .fullScreenCover(isPresented: Binding(
            get: { settingsVM?.isConnectingAccount == true && settingsVM?.linkToken != nil },
            set: { if !$0 { settingsVM?.isConnectingAccount = false } }
        )) {
            if let token = settingsVM?.linkToken {
                ConnectAccountView(
                    linkToken: token,
                    onSuccess: { publicToken, metadata in
                        Task {
                            await settingsVM?.handlePlaidSuccess(publicToken: publicToken, metadata: metadata)
                            viewModel?.refresh()
                        }
                    },
                    onExit: {
                        settingsVM?.isConnectingAccount = false
                    }
                )
            }
        }
        .alert("Error", isPresented: Binding(
            get: { settingsVM?.errorMessage != nil },
            set: { if !$0 { settingsVM?.errorMessage = nil } }
        )) {
            Button("OK") { settingsVM?.errorMessage = nil }
        } message: {
            Text(settingsVM?.errorMessage ?? "")
        }
        .alert("Success", isPresented: Binding(
            get: { settingsVM?.successMessage != nil },
            set: { if !$0 { settingsVM?.successMessage = nil } }
        )) {
            Button("OK") { settingsVM?.successMessage = nil }
        } message: {
            Text(settingsVM?.successMessage ?? "")
        }
        .onAppear {
            if viewModel == nil {
                let vm = AccountsViewModel(accountRepo: accountRepo, netWorthRepo: netWorthRepo)
                viewModel = vm
                vm.loadData()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: AccountsViewModel) -> some View {
        ScrollView {
            VStack(spacing: CrownTheme.sectionSpacing) {
                // Segment picker
                Picker("", selection: Binding(
                    get: { vm.selectedSegment },
                    set: { vm.selectedSegment = $0 }
                )) {
                    ForEach(AccountsViewModel.Segment.allCases) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)

                // Hero card
                heroCard(vm: vm)

                // Chart (net worth segment only)
                if vm.selectedSegment == .netWorth && !vm.snapshots.isEmpty {
                    NetWorthChartView(snapshots: vm.snapshots)
                }

                // Account groups
                ForEach(vm.accountGroups, id: \.title) { group in
                    accountGroupCard(title: group.title, accounts: group.accounts)
                }
            }
            .padding(.horizontal, CrownTheme.horizontalPadding)
            .padding(.bottom, CrownTheme.sectionSpacing)
        }
        .background(CrownTheme.screenBackground)
        .refreshable { vm.refresh() }
    }

    // MARK: - Hero Card

    private func heroCard(vm: AccountsViewModel) -> some View {
        VStack(spacing: 8) {
            Text(vm.selectedSegment == .netWorth ? "Total Net Worth" : vm.selectedSegment.rawValue)
                .font(CrownTheme.captionFont)
                .foregroundStyle(.secondary)

            CurrencyText(amount: vm.segmentTotal, font: CrownTheme.largeCurrencyFont)

            if vm.selectedSegment == .netWorth {
                let change = vm.netWorthChange
                let percent = vm.netWorthChangePercent
                if change != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))
                        CurrencyText(amount: abs(change), font: CrownTheme.captionFont, showAbsoluteValue: true)
                        Text(String(format: "(%.1f%%)", abs(percent)))
                            .font(CrownTheme.captionFont)
                        Text("1 month")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(change >= 0 ? CrownTheme.income : CrownTheme.expense)
                }

                Divider()

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
        }
        .crownCard()
    }

    // MARK: - Account Group Card

    private func accountGroupCard(title: String, accounts: [Account]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Group header
            HStack {
                Text(title)
                    .font(CrownTheme.headlineFont)
                    .foregroundStyle(Color.adaptiveNavy)
                Spacer()
                let total = accounts.reduce(0) { $0 + $1.balance }
                CurrencyText(amount: title == "Credit" ? abs(total) : total, font: CrownTheme.headlineFont)
            }
            .padding(.horizontal, CrownTheme.cardPadding)
            .padding(.top, CrownTheme.cardPadding)

            // Percentage of assets
            let totalAssets = viewModel?.totalAssets ?? 1
            if totalAssets > 0 && title != "Credit" {
                let groupTotal = accounts.reduce(0) { $0 + $1.balance }
                let pct = (groupTotal / totalAssets) * 100
                Text(String(format: "%.0f%% of assets", pct))
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, CrownTheme.cardPadding)
                    .padding(.top, 2)
            }

            Divider()
                .padding(.top, 8)

            // Account rows
            ForEach(accounts) { account in
                HStack(spacing: 12) {
                    Image(systemName: account.type.systemImage)
                        .font(.system(size: 16))
                        .foregroundStyle(CrownTheme.primaryBlue)
                        .frame(width: 36, height: 36)
                        .background(Color.adaptiveLightBlue)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                            .font(CrownTheme.subheadFont)
                        Text(account.type.displayName)
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        CurrencyText(amount: account.balance, font: CrownTheme.subheadFont)
                        if let synced = account.lastSynced {
                            Text(synced.formatted(.relative(presentation: .named)))
                                .font(CrownTheme.caption2Font)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.horizontal, CrownTheme.cardPadding)
                .padding(.vertical, 10)

                if account.id != accounts.last?.id {
                    Divider().padding(.leading, CrownTheme.cardPadding + 48)
                }
            }
        }
        .padding(.bottom, 8)
        .crownCard(padding: 0)
    }

    // MARK: - Helpers

    @discardableResult
    private func ensureSettingsVM() -> SettingsViewModel {
        if let existing = settingsVM { return existing }
        let created = SettingsViewModel(
            accountRepo:     accountRepo,
            transactionRepo: transactionRepo,
            netWorthRepo:    netWorthRepo,
            modelContext:    modelContext
        )
        settingsVM = created
        return created
    }
}

#Preview {
    NavigationStack { AccountsView() }
}
