import SwiftUI
import Charts

struct SpendingCardView: View {
    let categories: [(category: TransactionCategory, total: Double)]

    private var maxTotal: Double {
        categories.map(\.total).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Spending")
                    .font(CrownTheme.headlineFont)
                Spacer()
                Text(Date().relativeMonthLabel)
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            if categories.isEmpty {
                Text("No expenses this month.")
                    .font(CrownTheme.subheadFont)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                Chart(categories, id: \.category) { item in
                    BarMark(
                        x: .value("Amount", item.total),
                        y: .value("Category", "\(item.category.emoji) \(item.category.rawValue)")
                    )
                    .foregroundStyle(CrownTheme.primaryBlue.gradient)
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(item.total, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(CrownTheme.caption2Font)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(CrownTheme.captionFont)
                    }
                }
                .frame(height: CGFloat(categories.count) * 36 + 20)
            }
        }
        .crownCard()
    }
}

#Preview {
    SpendingCardView(categories: [
        (category: .groceries,      total: 423),
        (category: .dining,         total: 310),
        (category: .shopping,       total: 245),
        (category: .transportation, total: 180),
        (category: .subscriptions,  total: 95)
    ])
    .padding()
    .background(CrownTheme.screenBackground)
}
