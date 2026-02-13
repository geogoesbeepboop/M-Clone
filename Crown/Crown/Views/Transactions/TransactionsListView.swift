import SwiftUI

/// Main transactions screen.
///
/// Features:
/// - Searchable by merchant name or notes
/// - Category and account filter sheet
/// - Transactions grouped by date (section headers)
/// - Tap any row to open detail/edit sheet
/// - Pull-to-refresh syncs from Plaid (or reloads mock data)
///
/// Architecture note:
/// `TransactionsViewModel` holds the loaded data and filter state.
/// The view is purely declarative — it observes the VM and triggers mutations.
struct TransactionsListView: View {
    @Environment(\.transactionRepository) private var transactionRepo
    @Environment(\.accountRepository)    private var accountRepo
    @Environment(\.showChat)            private var showChat

    @State private var viewModel: TransactionsViewModel?
    @State private var showFilter      = false
    @State private var selectedTxn: Transaction? = nil

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                let vm = TransactionsViewModel(transactionRepo: transactionRepo)
                viewModel = vm
                vm.loadTransactions()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: TransactionsViewModel) -> some View {
        List {
            if vm.groupedByDate.isEmpty {
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "No Results",
                    message: vm.searchText.isEmpty
                        ? "No transactions found."
                        : "No transactions match \"\(vm.searchText)\"."
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(vm.groupedByDate, id: \.dateLabel) { group in
                    Section(group.dateLabel) {
                        ForEach(group.transactions) { txn in
                            Button {
                                selectedTxn = txn
                            } label: {
                                TransactionRowView(transaction: txn)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(
            text: Binding(
                get: { vm.searchText },
                set: { vm.searchText = $0 }
            ),
            prompt: "Search merchant or notes"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        showFilter = true
                    } label: {
                        Image(systemName: vm.hasActiveFilters
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(vm.hasActiveFilters
                                         ? CrownTheme.accentRed
                                         : CrownTheme.primaryBlue)
                    }
                    .accessibilityLabel(vm.hasActiveFilters ? "Filters active" : "Filter transactions")

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
            vm.refresh()
        }
        .sheet(isPresented: $showFilter) {
            TransactionFilterView(
                selectedCategory: Binding(
                    get: { vm.selectedCategory },
                    set: { vm.selectedCategory = $0 }
                ),
                selectedAccount: Binding(
                    get: { vm.selectedAccount },
                    set: { vm.selectedAccount = $0 }
                ),
                availableAccounts: accountRepo.fetchVisible()
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedTxn) { txn in
            TransactionDetailView(transaction: txn) { category, notes in
                vm.updateTransaction(txn, category: category, notes: notes)
                vm.refresh()
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    NavigationStack { TransactionsListView() }
}
