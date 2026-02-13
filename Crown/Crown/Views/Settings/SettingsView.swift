import SwiftUI
import SwiftData

/// App settings — bank account connections, data sync, and app info.
///
/// Presented as a sheet from the Dashboard toolbar gear icon.
struct SettingsView: View {

    @Environment(\.accountRepository)     private var accountRepo
    @Environment(\.transactionRepository) private var transactionRepo
    @Environment(\.netWorthRepository)    private var netWorthRepo
    @Environment(\.modelContext)          private var modelContext
    @Environment(\.dismiss)              private var dismiss

    @State private var viewModel: SettingsViewModel?

    private var vm: SettingsViewModel {
        if let viewModel { return viewModel }
        return SettingsViewModel(
            accountRepo:     accountRepo,
            transactionRepo: transactionRepo,
            netWorthRepo:    netWorthRepo,
            modelContext:    modelContext
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    settingsContent(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(CrownTheme.primaryBlue)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let created = SettingsViewModel(
                    accountRepo:     accountRepo,
                    transactionRepo: transactionRepo,
                    netWorthRepo:    netWorthRepo,
                    modelContext:    modelContext
                )
                viewModel = created
                created.loadData()
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func settingsContent(vm: SettingsViewModel) -> some View {
        List {
            // MARK: Bank Connections
            Section {
                if vm.connectedAccounts.isEmpty {
                    connectBankRow(vm: vm)
                } else {
                    ForEach(vm.connectedAccounts) { account in
                        connectedAccountRow(account, vm: vm)
                    }
                    connectBankRow(vm: vm)
                }
            } header: {
                Text("Bank Accounts")
            } footer: {
                if AppConfig.isPlaidConfigured {
                    Text("Crown uses Plaid to securely connect to your bank.")
                } else {
                    Text("Configure PLAID_CLIENT_ID and PLAID_SECRET in your Xcode scheme to enable real bank connections.")
                        .foregroundStyle(CrownTheme.expense)
                }
            }

            // MARK: Sync
            if !vm.connectedAccounts.isEmpty {
                Section("Data Sync") {
                    Button {
                        Task { await vm.syncAllAccounts() }
                    } label: {
                        HStack {
                            Label("Sync All Accounts", systemImage: "arrow.clockwise")
                            Spacer()
                            if vm.isSyncing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(vm.isSyncing)
                    .foregroundStyle(CrownTheme.primaryBlue)
                }
            }

            // MARK: Appearance
            Section("Appearance") {
                Picker(selection: Binding(
                    get: { vm.appearanceMode },
                    set: { vm.appearanceMode = $0 }
                )) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                } label: {
                    Label("Theme", systemImage: "moon.circle")
                }
                .tint(CrownTheme.primaryBlue)
            }

            // MARK: Demo Data
            Section {
                Toggle(isOn: Binding(
                    get: { vm.useMockData },
                    set: { newValue in
                        vm.useMockData = newValue
                        if newValue { vm.seedMockData() }
                    }
                )) {
                    Label("Use Demo Data", systemImage: "cylinder.fill")
                }
                .tint(CrownTheme.primaryBlue)

                if vm.useMockData {
                    Button {
                        vm.seedMockData()
                    } label: {
                        Label("Reload Demo Data", systemImage: "arrow.clockwise")
                            .foregroundStyle(CrownTheme.primaryBlue)
                    }
                }
            } header: {
                Text("Demo Data")
            } footer: {
                Text(vm.useMockData
                    ? "The app is populated with realistic sample accounts and transactions. Toggle off once you connect a real bank account."
                    : "Demo data is off. Connect a bank account above to see your real financial data."
                )
            }

            // MARK: About
            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Build") {
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundStyle(.secondary)
                }
                Link(destination: URL(string: "https://plaid.com/legal/")!) {
                    Label("Plaid Privacy Policy", systemImage: "link")
                }
                .foregroundStyle(CrownTheme.primaryBlue)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .alert("Success", isPresented: Binding(
            get: { vm.successMessage != nil },
            set: { if !$0 { vm.successMessage = nil } }
        )) {
            Button("OK") { vm.successMessage = nil }
        } message: {
            Text(vm.successMessage ?? "")
        }
        .fullScreenCover(isPresented: Binding(
            get: { vm.isConnectingAccount && vm.linkToken != nil },
            set: { if !$0 { vm.isConnectingAccount = false } }
        )) {
            if let token = vm.linkToken {
                ConnectAccountView(
                    linkToken: token,
                    onSuccess: { publicToken, metadata in
                        Task { await vm.handlePlaidSuccess(publicToken: publicToken, metadata: metadata) }
                    },
                    onExit: {
                        vm.isConnectingAccount = false
                    }
                )
            }
        }
    }

    // MARK: - Subviews

    private func connectBankRow(vm: SettingsViewModel) -> some View {
        Button {
            Task { await vm.startConnectFlow() }
        } label: {
            HStack {
                Label("Connect a Bank Account", systemImage: "plus.circle.fill")
                    .foregroundStyle(CrownTheme.primaryBlue)
                Spacer()
                if vm.isSyncing {
                    ProgressView()
                }
            }
        }
        .disabled(vm.isSyncing)
    }

    private func connectedAccountRow(_ account: Account, vm: SettingsViewModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: account.type.systemImage)
                .font(.title3)
                .foregroundStyle(CrownTheme.primaryBlue)
                .frame(width: 36, height: 36)
                .background(Color.adaptiveLightBlue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(CrownTheme.subheadFont)
                if let synced = account.lastSynced {
                    Text("Last synced \(synced.formatted(.relative(presentation: .named)))")
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    vm.disconnectAccount(account)
                } label: {
                    Label("Disconnect", systemImage: "link.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}
