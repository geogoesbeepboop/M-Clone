import SwiftUI
import Charts

/// Drill-down view for a single budget category.
///
/// Shows:
/// - A donut chart visualizing spent vs. remaining budget
/// - The month's transactions in that category
/// - An inline editor for the monthly limit
///
/// Future extensions:
/// - Chart showing spending trend for this category over past 6 months
/// - Sub-category breakdown (e.g., Groceries → Store A, Store B)
struct BudgetCategoryDetailView: View {
    let category: BudgetCategory
    let transactions: [Transaction]
    let spent: Double
    var onUpdateLimit: (Double) -> Void

    @State private var showEditLimit = false
    @State private var limitText: String = ""

    private var remaining: Double { max(category.monthlyLimit - spent, 0) }
    private var isOverBudget: Bool { spent > category.monthlyLimit }
    private var progress: Double { category.monthlyLimit > 0 ? spent / category.monthlyLimit : 0 }
    private var spentColor: Color { CrownTheme.budgetColor(for: progress) }

    var body: some View {
        ScrollView {
            VStack(spacing: CrownTheme.sectionSpacing) {
                // Donut chart
                donutChart

                // Transaction list
                if transactions.isEmpty {
                    EmptyStateView(
                        systemImage: category.emoji,
                        title: "No Transactions",
                        message: "No \(category.name.lowercased()) spending this month."
                    )
                    .frame(height: 200)
                } else {
                    VStack(spacing: 0) {
                        ForEach(transactions) { txn in
                            TransactionRowView(transaction: txn)
                                .padding(.horizontal, CrownTheme.cardPadding)
                            if txn.id != transactions.last?.id {
                                Divider().padding(.leading, CrownTheme.cardPadding + 52)
                            }
                        }
                    }
                    .crownCard(padding: 0)
                }
            }
            .padding(.horizontal, CrownTheme.horizontalPadding)
            .padding(.bottom, CrownTheme.sectionSpacing)
        }
        .background(CrownTheme.screenBackground)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit Limit") {
                    limitText = String(format: "%.0f", category.monthlyLimit)
                    showEditLimit = true
                }
                .tint(CrownTheme.primaryBlue)
            }
        }
        .sheet(isPresented: $showEditLimit) {
            editLimitSheet
        }
    }

    // MARK: - Donut Chart

    private var donutChart: some View {
        VStack(spacing: 12) {
            ZStack {
                Chart {
                    SectorMark(
                        angle: .value("Spent", spent),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .foregroundStyle(spentColor)
                    .cornerRadius(4)

                    SectorMark(
                        angle: .value("Remaining", max(category.monthlyLimit - spent, 0)),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(.secondarySystemFill))
                    .cornerRadius(4)
                }
                .frame(width: 180, height: 180)

                // Center text
                VStack(spacing: 2) {
                    CurrencyText(amount: spent, font: .system(size: 20, weight: .bold, design: .rounded), showAbsoluteValue: true)
                    Text("of \(category.monthlyLimit, format: .currency(code: "USD").precision(.fractionLength(0)))")
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
            }

            // Legend
            HStack(spacing: 20) {
                LegendItem(color: spentColor, label: "Spent")
                LegendItem(color: Color(.secondarySystemFill), label: "Remaining")
            }
        }
        .crownCard()
    }

    // MARK: - Edit Limit Sheet

    private var editLimitSheet: some View {
        NavigationStack {
            Form {
                Section("Monthly Limit for \(category.name)") {
                    HStack {
                        Text("$")
                        TextField("Amount", text: $limitText)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Edit Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showEditLimit = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let newLimit = Double(limitText), newLimit > 0 {
                            onUpdateLimit(newLimit)
                        }
                        showEditLimit = false
                    }
                    .fontWeight(.semibold)
                    .tint(CrownTheme.primaryBlue)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(CrownTheme.captionFont).foregroundStyle(.secondary)
        }
    }
}
