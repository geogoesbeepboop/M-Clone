import SwiftUI

/// Dashboard placeholder card for investment holdings.
///
/// Matches the BofA dashboard "Investments" card with empty state.
struct InvestmentsCardView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("$0 investments")
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
                Text("Today")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            // Top movers section
            Text("Top movers today")
                .font(CrownTheme.captionFont)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)
                .padding(.top, 4)

            // Empty state
            VStack(spacing: 8) {
                Text("No investment holdings with known securities")
                    .font(CrownTheme.headlineFont)
                    .multilineTextAlignment(.center)

                Text("Please sync another investment account to see top movers")
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
    InvestmentsCardView()
        .padding()
        .background(CrownTheme.screenBackground)
}
