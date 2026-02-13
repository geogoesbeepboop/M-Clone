import SwiftUI
import Charts

struct SpendingCardView: View {
    let spendingData: [DailySpending]
    let thisMonthTotal: Double
    let lastMonthTotal: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Spending")
                    .font(CrownTheme.headlineFont)
                Spacer()
                Image(systemName: "ellipsis")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            // Hero totals
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(thisMonthTotal, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(CrownTheme.currencyFont)
                    .foregroundStyle(Color.adaptiveNavy)
                Text("this month")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Text(lastMonthTotal, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text("last month")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }

            // Cumulative spending line chart
            if !spendingData.isEmpty {
                Chart(spendingData) { point in
                    LineMark(
                        x: .value("Day", point.dayOfMonth),
                        y: .value("Spent", point.cumulativeAmount)
                    )
                    .foregroundStyle(by: .value("Period", point.label))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: point.label == "This month" ? 2.5 : 1.5))

                    if point.label == "This month" {
                        AreaMark(
                            x: .value("Day", point.dayOfMonth),
                            y: .value("Spent", point.cumulativeAmount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CrownTheme.accentRed.opacity(0.25), CrownTheme.accentRed.opacity(0.05), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartForegroundStyleScale([
                    "This month": CrownTheme.accentRed,
                    "Last month": Color.secondary.opacity(0.4)
                ])
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .chartYScale(domain: .automatic(includesZero: true))
                .frame(height: 120)
            } else {
                Text("No spending data available.")
                    .font(CrownTheme.subheadFont)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }

            // Legend
            if !spendingData.isEmpty {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(CrownTheme.accentRed)
                            .frame(width: 8, height: 8)
                        Text("This month")
                            .font(CrownTheme.caption2Font)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                        Text("Last month")
                            .font(CrownTheme.caption2Font)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .crownCard()
    }
}

#Preview {
    let data: [DailySpending] = (1...28).map { day in
        DailySpending(dayOfMonth: day, cumulativeAmount: Double(day) * 85, label: "Last month")
    } + (1...15).map { day in
        DailySpending(dayOfMonth: day, cumulativeAmount: Double(day) * 95, label: "This month")
    }
    return SpendingCardView(
        spendingData: data,
        thisMonthTotal: 1425,
        lastMonthTotal: 2380
    )
    .padding()
    .background(CrownTheme.screenBackground)
}
