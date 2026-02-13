import SwiftUI

// MARK: - Primary Button (BofA blue, full-width)

struct CrownPrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CrownTheme.headlineFont)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isDestructive ? CrownTheme.accentRed : CrownTheme.primaryBlue)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button (outlined)

struct CrownSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CrownTheme.headlineFont)
            .foregroundStyle(CrownTheme.primaryBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(CrownTheme.primaryBlue, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Convenience extensions

extension ButtonStyle where Self == CrownPrimaryButtonStyle {
    static var crownPrimary: CrownPrimaryButtonStyle { CrownPrimaryButtonStyle() }
    static var crownDestructive: CrownPrimaryButtonStyle { CrownPrimaryButtonStyle(isDestructive: true) }
}

extension ButtonStyle where Self == CrownSecondaryButtonStyle {
    static var crownSecondary: CrownSecondaryButtonStyle { CrownSecondaryButtonStyle() }
}
