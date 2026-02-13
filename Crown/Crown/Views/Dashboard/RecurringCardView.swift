import SwiftUI

/// Dashboard placeholder card for recurring bills/subscriptions.
///
/// Matches the BofA dashboard "Recurring" card with empty state.
struct RecurringCardView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Recurring")
                    .font(CrownTheme.headlineFont)
                Spacer()
                Image(systemName: "ellipsis")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            // Subtitle
            HStack(spacing: 4) {
                Text("$0 remaining due")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            // Empty state
            VStack(spacing: 12) {
                Text("There are no more recurring items this month")
                    .font(CrownTheme.subheadFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("View recurring") {}
                    .font(CrownTheme.subheadFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(CrownTheme.primaryBlue)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .crownCard()
    }
}

#Preview {
    RecurringCardView()
        .padding()
        .background(CrownTheme.screenBackground)
}
