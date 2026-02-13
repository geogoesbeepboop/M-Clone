import SwiftUI

/// A single row in the budget overview list.
///
/// Shows: emoji + category name, "$spent / $limit" text, and a color-coded progress bar.
/// The bar turns red when spending exceeds the monthly limit.
struct BudgetCategoryRowView: View {
    let category: BudgetCategory
    let spent: Double
    let progress: Double   // 0.0 to 1.0+

    private var remaining: Double { category.monthlyLimit - spent }
    private var isOverBudget: Bool { progress > 1.0 }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Emoji + name
                HStack(spacing: 8) {
                    Text(category.emoji)
                        .font(.body)
                    Text(category.name)
                        .font(CrownTheme.subheadFont)
                }

                Spacer()

                // Spent / limit
                HStack(spacing: 4) {
                    CurrencyText(
                        amount: spent,
                        font: CrownTheme.captionFont,
                        colorCoded: false,
                        showAbsoluteValue: true
                    )
                    Text("/")
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(.tertiary)
                    CurrencyText(
                        amount: category.monthlyLimit,
                        font: CrownTheme.captionFont,
                        colorCoded: false
                    )
                }
                .foregroundStyle(.secondary)
            }

            ProgressBarView(
                progress: progress,
                tint: CrownTheme.budgetColor(for: progress)
            )

            // Over-budget warning
            if isOverBudget {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(CrownTheme.budgetRed)
                    Text("Over budget by \(abs(remaining), format: .currency(code: "USD").precision(.fractionLength(0)))")
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(CrownTheme.budgetRed)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}
