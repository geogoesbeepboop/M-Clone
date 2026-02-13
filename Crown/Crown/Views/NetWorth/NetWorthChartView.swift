import SwiftUI
import Charts

/// Time range selector for the net worth chart.
enum NetWorthTimeRange: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "ALL"

    var id: String { rawValue }
    var label: String { rawValue }

    /// Number of months to show, or nil for all data.
    var months: Int? {
        switch self {
        case .oneMonth: 1
        case .threeMonths: 3
        case .sixMonths: 6
        case .oneYear: 12
        case .all: nil
        }
    }
}

/// Flush edge-to-edge line chart showing net worth over time.
///
/// Renders without a card wrapper so it bleeds to screen edges with
/// an artistic gradient fill underneath the line.
struct NetWorthChartView: View {
    let snapshots: [NetWorthSnapshot]

    @State private var selectedRange: NetWorthTimeRange = .oneYear

    private var filteredSnapshots: [NetWorthSnapshot] {
        guard let months = selectedRange.months else { return snapshots }
        let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
        return snapshots.filter { $0.date >= cutoff }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Time range selector pills
            HStack(spacing: 0) {
                ForEach(NetWorthTimeRange.allCases) { range in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRange = range
                        }
                    } label: {
                        Text(range.label)
                            .font(CrownTheme.captionFont)
                            .fontWeight(selectedRange == range ? .semibold : .regular)
                            .foregroundStyle(selectedRange == range ? CrownTheme.primaryBlue : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedRange == range
                                    ? CrownTheme.primaryBlue.opacity(0.1)
                                    : Color.clear
                            )
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }

            // Chart — flush to edges
            if filteredSnapshots.count > 1 {
                Chart(filteredSnapshots) { snapshot in
                    AreaMark(
                        x: .value("Month", snapshot.date),
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

                    LineMark(
                        x: .value("Month", snapshot.date),
                        y: .value("Net Worth", snapshot.netWorth)
                    )
                    .foregroundStyle(CrownTheme.primaryBlue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: max(filteredSnapshots.count / 4, 1))) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .font(CrownTheme.caption2Font)
                    }
                }
                .chartYAxis(.hidden)
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 200)
                .padding(.horizontal, -CrownTheme.horizontalPadding)
            } else {
                Text("Not enough data to display chart")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 200)
            }
        }
    }
}
