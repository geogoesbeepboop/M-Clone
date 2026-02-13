import SwiftUI

/// Central design system for Crown — Bank of America visual identity.
///
/// All colors, fonts, and spacing constants live here so every view
/// is consistent and dark-mode-safe without hard-coding values.
enum CrownTheme {

    // MARK: - Brand Colors (BofA authentic palette)

    /// BofA primary blue — buttons, links, active tab icons, interactive elements
    static let primaryBlue = Color(hex: 0x0056B3)

    /// BofA signature red — section dividers, expense amounts, key accents
    static let accentRed   = Color(hex: 0xE31837)

    /// BofA dark navy — hero numbers, card headlines, primary text emphasis
    static let darkNavy    = Color(hex: 0x012169)

    /// Light blue chip background for icons and tags
    static let lightBlue     = Color(hex: 0xE5F0FB)
    static let lightBlueDark = Color(hex: 0x1A2E42)  // dark-mode variant

    // MARK: - Semantic Colors

    static let income  = Color(hex: 0x1E8B3C)   // money-in green
    static let expense = Color(hex: 0xE31837)   // money-out red (matches BofA red)
    static let warning = Color(hex: 0xE57200)   // amber

    /// Budget progress — green (under 75%), yellow (75–100%), red (over 100%)
    static let budgetGreen = Color(hex: 0x28A745)  // success green
    static let budgetYellow = Color(hex: 0xE5A100) // warning amber
    static let budgetRed   = Color(hex: 0xDC3545)  // danger red

    /// Kept for legacy call-sites — maps to green
    static let budgetProgress     = budgetGreen
    /// Kept for legacy call-sites — maps to red
    static let budgetOverProgress = budgetRed

    /// Returns the appropriate budget color for a given progress ratio.
    static func budgetColor(for progress: Double) -> Color {
        switch progress {
        case ..<0.75:  return budgetGreen
        case 0.75...1: return budgetYellow
        default:       return budgetRed
        }
    }

    // MARK: - Adaptive Backgrounds (auto light/dark)

    static let cardBackground      = Color(.systemBackground)
    static let screenBackground    = Color(.systemGroupedBackground)
    static let tertiaryBackground  = Color(.tertiarySystemBackground)

    // MARK: - Typography

    static let largeTitleFont    = Font.system(size: 34, weight: .bold)
    static let titleFont         = Font.system(size: 22, weight: .bold)
    static let headlineFont      = Font.system(size: 17, weight: .semibold)
    static let bodyFont          = Font.system(size: 17, weight: .regular)
    static let subheadFont       = Font.system(size: 15, weight: .regular)
    static let captionFont       = Font.system(size: 13, weight: .regular)
    static let caption2Font      = Font.system(size: 11, weight: .regular)
    static let currencyFont      = Font.system(size: 28, weight: .bold, design: .rounded)
    static let largeCurrencyFont = Font.system(size: 36, weight: .bold, design: .rounded)

    // MARK: - Spacing & Layout

    static let cardPadding:       CGFloat = 16
    static let cardCornerRadius:  CGFloat = 10
    static let sectionSpacing:    CGFloat = 20
    static let itemSpacing:       CGFloat = 12
    static let horizontalPadding: CGFloat = 16

    // MARK: - Shadow (subtle — BofA uses clean borders, not heavy drops)

    static let cardShadowColor:  Color   = Color.black.opacity(0.05)
    static let cardShadowRadius: CGFloat = 3
    static let cardShadowY:      CGFloat = 1
}

// MARK: - Color(hex:) extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red:     Double((hex >> 16) & 0xFF) / 255.0,
            green:   Double((hex >>  8) & 0xFF) / 255.0,
            blue:    Double( hex        & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Adaptive helpers

extension Color {
    /// Light blue chip background — adapts to dark mode.
    static var adaptiveLightBlue: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(CrownTheme.lightBlueDark)
                : UIColor(CrownTheme.lightBlue)
        })
    }

    /// Deep navy in light mode, near-white in dark mode — for hero numbers.
    static var adaptiveNavy: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor(CrownTheme.darkNavy)
        })
    }
}
