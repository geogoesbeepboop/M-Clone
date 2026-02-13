import SwiftUI
import Charts

/// Cash Flow report — grouped bar chart showing income vs. expenses per month
/// for the past 6 months.
///
/// Each month gets two bars (income = green, expenses = red) placed side-by-side.
struct CashFlowReportView: View {
    let viewModel: ReportsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: CrownTheme.sectionSpacing) {
                // Chart card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last 6 Months")
                        .font(CrownTheme.headlineFont)

                    Chart(viewModel.cashFlowByMonth) { item in
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Income", item.income),
                            width: .ratio(0.4)
                        )
                        .foregroundStyle(CrownTheme.income.gradient)
                        .position(by: .value("Type", "Income"))
                        .cornerRadius(4)

                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Expenses", item.expenses),
                            width: .ratio(0.4)
                        )
                        .foregroundStyle(CrownTheme.expense.gradient)
                        .position(by: .value("Type", "Expenses"))
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .font(CrownTheme.captionFont)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(v, format: .currency(code: "USD").precision(.fractionLength(0)))
                                        .font(CrownTheme.caption2Font)
                                }
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(.secondary.opacity(0.3))
                        }
                    }
                    .frame(height: 220)

                    // Legend
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Circle().fill(CrownTheme.income).frame(width: 10, height: 10)
                            Text("Income").font(CrownTheme.captionFont).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 6) {
                            Circle().fill(CrownTheme.expense).frame(width: 10, height: 10)
                            Text("Expenses").font(CrownTheme.captionFont).foregroundStyle(.secondary)
                        }
                    }
                }
                .crownCard()

                // Monthly summary table
                VStack(spacing: 0) {
                    ForEach(viewModel.cashFlowByMonth.reversed()) { item in
                        HStack {
                            Text(item.month.shortMonthYearString)
                                .font(CrownTheme.subheadFont)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                CurrencyText(amount: item.net, font: CrownTheme.subheadFont, showSign: true, colorCoded: true)
                                Text("In: \(item.income, format: .currency(code: "USD").precision(.fractionLength(0)))  Out: \(item.expenses, format: .currency(code: "USD").precision(.fractionLength(0)))")
                                    .font(CrownTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, CrownTheme.cardPadding)
                        .padding(.vertical, 10)

                        if item.id != viewModel.cashFlowByMonth.reversed().last?.id {
                            Divider().padding(.leading, CrownTheme.cardPadding)
                        }
                    }
                }
                .crownCard(padding: 0)
            }
            .padding(.horizontal, CrownTheme.horizontalPadding)
            .padding(.bottom, CrownTheme.sectionSpacing)
        }
        .background(CrownTheme.screenBackground)
        .navigationTitle("Cash Flow")
        .navigationBarTitleDisplayMode(.inline)
    }
}
