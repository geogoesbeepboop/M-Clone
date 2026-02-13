import SwiftUI

/// Dashboard placeholder card for savings goals.
///
/// Matches the BofA dashboard "Goals" card with empty state.
struct GoalsCardView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Goals")
                    .font(CrownTheme.headlineFont)
                Spacer()
                Image(systemName: "ellipsis")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            // Subtitle
            HStack(spacing: 4) {
                Text("$0")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Text("This month")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            // Empty state
            VStack(spacing: 8) {
                Text("Start your first goal")
                    .font(CrownTheme.headlineFont)
                    .multilineTextAlignment(.center)

                Text("Put your savings to work and start saving up for something great.")
                    .font(CrownTheme.subheadFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .crownCard()
    }
}

#Preview {
    GoalsCardView()
        .padding()
        .background(CrownTheme.screenBackground)
}
