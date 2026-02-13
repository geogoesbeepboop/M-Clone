import SwiftUI
import Charts

struct NetWorthCardView: View {
    let netWorth: Double
    let change: Double
    let changePercent: Double
    let snapshots: [NetWorthSnapshot]

    private var trendColor: Color {
        change >= 0 ? CrownTheme.income : CrownTheme.expense
    }

    private var trendIcon: String {
        change >= 0 ? "arrow.up.right" : "arrow.down.right"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Net Worth")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.tertiary)
            }

            // Main figure in BofA navy
            CurrencyText(amount: netWorth, font: CrownTheme.largeCurrencyFont)
                .foregroundStyle(Color.adaptiveNavy)

            // Trend indicator
            HStack(spacing: 4) {
                Image(systemName: trendIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(trendColor)
                CurrencyText(amount: abs(change), font: CrownTheme.captionFont)
                    .foregroundStyle(trendColor)
                Text(String(format: "(%.1f%%)", abs(changePercent)))
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(trendColor)
                Text("this month")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            // Mini sparkline
            if snapshots.count > 1 {
                Chart(snapshots) { snapshot in
                    LineMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Net Worth", snapshot.netWorth)
                    )
                    .foregroundStyle(CrownTheme.primaryBlue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", snapshot.date),
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
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 60)
            }
        }
        .crownCard()
    }
}

#Preview {
    let snapshots = (0..<12).map { i -> NetWorthSnapshot in
        let date = Calendar.current.date(byAdding: .month, value: i - 11, to: Date()) ?? Date()
        return NetWorthSnapshot(date: date, totalAssets: 50000 + Double(i) * 900, totalLiabilities: 8500 - Double(i) * 110)
    }
    return NetWorthCardView(
        netWorth: 61300,
        change: 1020,
        changePercent: 1.7,
        snapshots: snapshots
    )
    .padding()
    .background(CrownTheme.screenBackground)
}
