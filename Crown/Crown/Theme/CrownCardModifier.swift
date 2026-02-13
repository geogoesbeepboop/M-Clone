import SwiftUI

/// Applies the standard Crown card appearance — white background, rounded corners,
/// subtle border, a light shadow matching BofA's clean card style, and the iconic
/// red/navy section divider at the top.
struct CrownCard: ViewModifier {
    var padding: CGFloat = CrownTheme.cardPadding
    var showDivider: Bool = true

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if showDivider {
                BofASectionDivider()
            }
            content
                .padding(padding)
        }
        .background(CrownTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CrownTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CrownTheme.cardCornerRadius, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
        .shadow(
            color:  CrownTheme.cardShadowColor,
            radius: CrownTheme.cardShadowRadius,
            x: 0,
            y: CrownTheme.cardShadowY
        )
    }
}

extension View {
    func crownCard(padding: CGFloat = CrownTheme.cardPadding, showDivider: Bool = true) -> some View {
        modifier(CrownCard(padding: padding, showDivider: showDivider))
    }
}

// MARK: - BofA Two-Tone Section Divider

/// The iconic Bank of America horizontal bar — red on the left, navy on the right.
/// Placed between major screen sections to mirror BofA's visual grouping language.
struct BofASectionDivider: View {
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(CrownTheme.accentRed)
                    .frame(width: geo.size.width * 0.35)
                Rectangle()
                    .fill(CrownTheme.darkNavy)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Section header style

struct CrownSectionHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(CrownTheme.headlineFont)
            .foregroundStyle(Color.adaptiveNavy)
    }
}

extension View {
    func crownSectionHeader() -> some View {
        modifier(CrownSectionHeader())
    }
}
