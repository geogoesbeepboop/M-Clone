import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.crownPrimary)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    EmptyStateView(
        systemImage: "list.bullet.rectangle",
        title: "No Transactions",
        message: "Connect a bank account or add transactions manually.",
        actionTitle: "Connect Account",
        action: {}
    )
}
