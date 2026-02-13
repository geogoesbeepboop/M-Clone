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
            // Header: "Net worth" + "..." menu (matches other card headers)
            HStack {
                Text("Net worth")
                    .font(CrownTheme.headlineFont)
                Spacer()
                Image(systemName: "ellipsis")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            // Amount
            CurrencyText(amount: netWorth, font: CrownTheme.currencyFont)
                .foregroundStyle(Color.adaptiveNavy)

            // Change indicator
            HStack(spacing: 4) {
                CurrencyText(amount: abs(change), font: CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text("1 month")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
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
                            colors: [CrownTheme.primaryBlue.opacity(0.4), CrownTheme.primaryBlue.opacity(0.05), .clear],
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
