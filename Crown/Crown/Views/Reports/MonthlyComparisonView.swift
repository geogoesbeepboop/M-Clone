import SwiftUI

/// Monthly Comparison report — compare spending by category between two selected months.
///
/// The user selects a primary month and a comparison month. Each category row shows
/// the spending for each month and whether it increased, decreased, or stayed flat.
struct MonthlyComparisonView: View {
    let viewModel: ReportsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: CrownTheme.sectionSpacing) {
                // Month selectors
                VStack(spacing: 12) {
                    HStack {
                        Text("Comparing")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    MonthSelectorView(
                        selectedMonth: Binding(
                            get: { viewModel.selectedMonth },
                            set: { viewModel.selectedMonth = $0 }
                        )
                    )
                    Divider()
                    HStack {
                        Text("Against")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    MonthSelectorView(
                        selectedMonth: Binding(
                            get: { viewModel.compareMonth },
                            set: { viewModel.compareMonth = $0 }
                        )
                    )
                }
                .crownCard()

                // Comparison table
                if viewModel.monthlyComparison.isEmpty {
                    EmptyStateView(
                        systemImage: "calendar",
                        title: "No Data",
                        message: "No spending data available for the selected months."
                    )
                    .frame(height: 200)
                } else {
                    // Column headers
                    HStack {
                        Text("Category")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(viewModel.selectedMonth.shortMonthYearString)
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .trailing)
                        Text(viewModel.compareMonth.shortMonthYearString)
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .trailing)
                        Text("Δ")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.horizontal, CrownTheme.cardPadding)

                    VStack(spacing: 0) {
                        ForEach(viewModel.monthlyComparison) { row in
                            HStack {
                                Text("\(row.category.emoji) \(row.category.rawValue)")
                                    .font(CrownTheme.captionFont)
                                    .lineLimit(1)
                                Spacer()
                                Text(row.primaryTotal, format: .currency(code: "USD").precision(.fractionLength(0)))
                                    .font(CrownTheme.captionFont)
                                    .frame(width: 70, alignment: .trailing)
                                Text(row.compareTotal, format: .currency(code: "USD").precision(.fractionLength(0)))
                                    .font(CrownTheme.captionFont)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 70, alignment: .trailing)
                                // Delta
                                Group {
                                    if row.difference > 0 {
                                        Text("+\(row.difference, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                            .foregroundStyle(CrownTheme.expense)
                                    } else if row.difference < 0 {
                                        Text("\(row.difference, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                            .foregroundStyle(CrownTheme.income)
                                    } else {
                                        Text("—")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(CrownTheme.captionFont)
                                .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.horizontal, CrownTheme.cardPadding)
                            .padding(.vertical, 8)

                            if row.id != viewModel.monthlyComparison.last?.id {
                                Divider().padding(.leading, CrownTheme.cardPadding)
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
        .navigationTitle("Compare Months")
        .navigationBarTitleDisplayMode(.inline)
    }
}
