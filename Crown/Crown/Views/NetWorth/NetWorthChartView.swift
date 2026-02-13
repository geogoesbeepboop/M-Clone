import SwiftUI
import Charts

/// Line chart showing net worth over a series of monthly snapshots.
///
/// Uses a `LineMark` overlaid on an `AreaMark` with a gradient fill for visual depth.
/// The y-axis domain excludes zero so the chart isn't compressed by a large baseline.
struct NetWorthChartView: View {
    let snapshots: [NetWorthSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("12-Month Trend")
                .font(CrownTheme.captionFont)
                .foregroundStyle(.secondary)

            Chart(snapshots) { snapshot in
                AreaMark(
                    x: .value("Month", snapshot.date),
                    y: .value("Net Worth", snapshot.netWorth)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [CrownTheme.primaryBlue.opacity(0.25), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Month", snapshot.date),
                    y: .value("Net Worth", snapshot.netWorth)
                )
                .foregroundStyle(CrownTheme.primaryBlue)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Month", snapshot.date),
                    y: .value("Net Worth", snapshot.netWorth)
                )
                .foregroundStyle(CrownTheme.primaryBlue)
                .symbolSize(20)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(CrownTheme.caption2Font)
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
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 180)
        }
        .crownCard()
    }
}
