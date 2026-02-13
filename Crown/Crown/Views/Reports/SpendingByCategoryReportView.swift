import SwiftUI
import Charts

/// Spending by Category report — donut chart + ranked table for a selected month.
///
/// Chart: SectorMark donut (innerRadius 60%) with category colors
/// Table: Sorted by spend descending, shows amount and percentage
struct SpendingByCategoryReportView: View {
    /// @Observable ViewModel — SwiftUI's Observation framework automatically
    /// re-renders this view when any property accessed in body changes.
    @State var viewModel: ReportsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: CrownTheme.sectionSpacing) {
                // Month selector
                MonthSelectorView(
                    selectedMonth: Binding(
                        get: { viewModel.selectedMonth },
                        set: { viewModel.selectedMonth = $0 }
                    )
                )

                // Donut chart
                if viewModel.spendingByCategory.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.pie",
                        title: "No Data",
                        message: "No expenses recorded for \(viewModel.selectedMonth.shortMonthYearString)."
                    )
                    .frame(height: 200)
                } else {
                    donutChart
                    categoryTable
                }
            }
            .padding(.horizontal, CrownTheme.horizontalPadding)
            .padding(.bottom, CrownTheme.sectionSpacing)
        }
        .background(CrownTheme.screenBackground)
        .navigationTitle("Spending")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var donutChart: some View {
        VStack(spacing: 12) {
            Chart(viewModel.spendingByCategory) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.60),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Category", item.category.rawValue))
                .cornerRadius(4)
            }
            .chartLegend(position: .bottom, alignment: .center, spacing: 8) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
                    ForEach(viewModel.spendingByCategory.prefix(8)) { item in
                        HStack(spacing: 4) {
                            Text(item.category.emoji)
                                .font(.caption2)
                            Text(item.category.rawValue)
                                .font(CrownTheme.caption2Font)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(height: 220)
        }
        .crownCard()
    }

    private var categoryTable: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.spendingByCategory) { item in
                HStack(spacing: 12) {
                    Text(item.category.emoji)
                        .font(.body)
                        .frame(width: 32, height: 32)
                        .background(Color.adaptiveLightBlue)
                        .clipShape(Circle())

                    Text(item.category.rawValue)
                        .font(CrownTheme.subheadFont)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        CurrencyText(amount: item.total, font: CrownTheme.subheadFont, showAbsoluteValue: true)
                        Text(String(format: "%.1f%%", item.percentage))
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, CrownTheme.cardPadding)
                .padding(.vertical, 10)

                if item.id != viewModel.spendingByCategory.last?.id {
                    Divider().padding(.leading, CrownTheme.cardPadding + 44)
                }
            }
        }
        .crownCard(padding: 0)
    }
}

