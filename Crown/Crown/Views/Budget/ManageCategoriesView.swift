import SwiftUI

/// Full CRUD interface for budget categories.
///
/// The user can:
/// - View all existing categories
/// - Add a new category (emoji, name, mapped TransactionCategory, monthly limit)
/// - Delete categories with swipe-to-delete
///
/// Future extensions:
/// - Reorder categories (drag handles)
/// - Edit existing category name / emoji / limit inline
/// - Category groups (Food, Home, etc.)
struct ManageCategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: BudgetViewModel

    @State private var showAddForm = false

    var body: some View {
        List {
            ForEach(viewModel.budgetCategories) { category in
                HStack {
                    Text(category.emoji)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(CrownTheme.subheadFont)
                        Text(category.category.rawValue)
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    CurrencyText(amount: category.monthlyLimit, font: CrownTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteCategory(viewModel.budgetCategories[index])
                }
            }

            Button {
                showAddForm = true
            } label: {
                Label("Add Category", systemImage: "plus.circle.fill")
                    .foregroundStyle(CrownTheme.primaryBlue)
            }
        }
        .navigationTitle("Manage Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton().tint(CrownTheme.primaryBlue)
            }
        }
        .sheet(isPresented: $showAddForm) {
            AddBudgetCategoryView { name, emoji, limit, category in
                viewModel.addCategory(name: name, emoji: emoji, limit: limit, category: category)
            }
        }
    }
}

// MARK: - Add Category Form

struct AddBudgetCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, String, Double, TransactionCategory) -> Void

    @State private var name: String = ""
    @State private var emoji: String = "💰"
    @State private var limitText: String = "200"
    @State private var selectedCategory: TransactionCategory = .other

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    HStack {
                        Text("Emoji")
                        Spacer()
                        TextField("Emoji", text: $emoji)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 44)
                    }
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("e.g. Groceries", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TransactionCategory.allCases) { cat in
                            Text("\(cat.emoji) \(cat.rawValue)").tag(cat)
                        }
                    }
                }

                Section("Monthly Limit") {
                    HStack {
                        Text("$")
                        TextField("Amount", text: $limitText)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
                              let limit = Double(limitText), limit > 0 else { return }
                        onAdd(name.trimmingCharacters(in: .whitespaces), emoji, limit, selectedCategory)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(CrownTheme.primaryBlue)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
