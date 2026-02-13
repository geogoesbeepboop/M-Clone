import SwiftUI

struct NotificationItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let timestamp: String
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    private let notifications: [NotificationItem] = [
        NotificationItem(
            icon: "creditcard.fill",
            iconColor: CrownTheme.primaryBlue,
            title: "Large purchase detected",
            message: "A $247.50 charge at Best Buy was posted to your checking account.",
            timestamp: "2h ago"
        ),
        NotificationItem(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: CrownTheme.income,
            title: "Spending insight",
            message: "You've spent 15% less on dining this month compared to last month.",
            timestamp: "5h ago"
        ),
        NotificationItem(
            icon: "dollarsign.circle.fill",
            iconColor: CrownTheme.primaryBlue,
            title: "Direct deposit received",
            message: "A deposit of $3,245.00 was received in your checking account.",
            timestamp: "1d ago"
        ),
        NotificationItem(
            icon: "exclamationmark.triangle.fill",
            iconColor: CrownTheme.warning,
            title: "Bill reminder",
            message: "Your electricity bill of $142.30 is due in 3 days.",
            timestamp: "1d ago"
        ),
        NotificationItem(
            icon: "arrow.up.right.circle.fill",
            iconColor: CrownTheme.income,
            title: "Net worth milestone",
            message: "Your net worth has increased by $1,020 this month. Keep it up!",
            timestamp: "2d ago"
        ),
        NotificationItem(
            icon: "bell.badge.fill",
            iconColor: CrownTheme.accentRed,
            title: "Subscription renewal",
            message: "Your Netflix subscription of $15.49 will renew tomorrow.",
            timestamp: "3d ago"
        )
    ]

    var body: some View {
        NavigationStack {
            List(notifications) { item in
                HStack(alignment: .top, spacing: 12) {
                    // Icon circle
                    Image(systemName: item.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(item.iconColor)
                        .clipShape(Circle())

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.title)
                                .font(CrownTheme.headlineFont)
                            Spacer()
                            Text(item.timestamp)
                                .font(CrownTheme.caption2Font)
                                .foregroundStyle(.tertiary)
                        }
                        Text(item.message)
                            .font(CrownTheme.subheadFont)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(CrownTheme.primaryBlue)
                }
            }
        }
    }
}

#Preview {
    NotificationsView()
}
