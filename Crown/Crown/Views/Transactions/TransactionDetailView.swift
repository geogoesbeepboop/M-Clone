import SwiftUI

/// Detail / edit sheet for a single transaction.
///
/// Allows the user to change:
/// - Category (via Picker)
/// - Notes (via TextField)
///
/// Future extensions:
/// - Merchant name rename
/// - Split transaction
/// - Attach photo receipts
/// - Tag management
struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction
    let onSave: (TransactionCategory, String) -> Void

    @State private var selectedCategory: TransactionCategory
    @State private var notes: String

    init(transaction: Transaction, onSave: @escaping (TransactionCategory, String) -> Void) {
        self.transaction = transaction
        self.onSave = onSave
        _selectedCategory = State(initialValue: transaction.category)
        _notes = State(initialValue: transaction.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Summary section — read-only
                Section("Transaction") {
                    LabeledContent("Merchant", value: transaction.merchant)
                    LabeledContent("Date") {
                        Text(transaction.date.formatted(date: .long, time: .omitted))
                    }
                    LabeledContent("Amount") {
                        CurrencyText(amount: transaction.amount, colorCoded: true)
                    }
                    if let accountName = transaction.account?.name {
                        LabeledContent("Account", value: accountName)
                    }
                    if transaction.isPending {
                        LabeledContent("Status") {
                            Text("Pending")
                                .foregroundStyle(.orange)
                        }
                    }
                }

                // Editable fields
                Section("Edit") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: "circle.fill")
                                .tag(cat)
                        }
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(selectedCategory, notes)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(CrownTheme.primaryBlue)
                }
            }
        }
    }
}
