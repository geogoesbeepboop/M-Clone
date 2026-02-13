import SwiftUI

/// Displays a monetary amount with consistent formatting across the app.
struct CurrencyText: View {
    let amount: Double
    var font: Font = CrownTheme.bodyFont
    var showSign: Bool = false
    var colorCoded: Bool = false
    var showAbsoluteValue: Bool = false

    private var displayAmount: Double {
        showAbsoluteValue ? abs(amount) : amount
    }

    private var textColor: Color {
        guard colorCoded else { return .primary }
        if amount > 0 { return CrownTheme.income }
        if amount < 0 { return CrownTheme.expense }
        return .secondary
    }

    var body: some View {
        Text(displayAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
            .font(font)
            .foregroundStyle(textColor)
            .monospacedDigit()
    }
}

#Preview {
    VStack(spacing: 8) {
        CurrencyText(amount: 4832.47, font: CrownTheme.currencyFont)
        CurrencyText(amount: -64.32, colorCoded: true)
        CurrencyText(amount: 2750.00, colorCoded: true)
    }
    .padding()
}
