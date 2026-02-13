import SwiftUI

/// Bottom-sheet filter panel for the transactions list.
///
/// Exposes:
/// - Category filter (single selection)
/// - Account filter (single selection from passed-in account list)
/// - Clear all filters action
///
/// Future extensions:
/// - Date range filter
/// - Amount range slider
/// - Pending-only toggle
struct TransactionFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedCategory: TransactionCategory?
    @Binding var selectedAccount: Account?
    let availableAccounts: [Account]

    var body: some View {
        NavigationStack {
            Form {
                // Category picker
                Section("Category") {
                    // "All" option
                    Button {
                        selectedCategory = nil
                    } label: {
                        HStack {
                            Label("All Categories", systemImage: "tray.2")
                            Spacer()
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(CrownTheme.primaryBlue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    ForEach(TransactionCategory.allCases) { cat in
                        Button {
                            selectedCategory = cat
                        } label: {
                            HStack {
                                Text("\(cat.emoji) \(cat.rawValue)")
                                Spacer()
                                if selectedCategory == cat {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(CrownTheme.primaryBlue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                // Account picker
                if !availableAccounts.isEmpty {
                    Section("Account") {
                        Button {
                            selectedAccount = nil
                        } label: {
                            HStack {
                                Label("All Accounts", systemImage: "building.columns")
                                Spacer()
                                if selectedAccount == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(CrownTheme.primaryBlue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)

                        ForEach(availableAccounts) { account in
                            Button {
                                selectedAccount = account
                            } label: {
                                HStack {
                                    Label(account.name, systemImage: account.type.systemImage)
                                    Spacer()
                                    if selectedAccount?.id == account.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(CrownTheme.primaryBlue)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                // Clear
                Section {
                    Button(role: .destructive) {
                        selectedCategory = nil
                        selectedAccount  = nil
                        dismiss()
                    } label: {
                        Label("Clear All Filters", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(CrownTheme.primaryBlue)
                }
            }
        }
    }
}
