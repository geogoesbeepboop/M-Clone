import SwiftUI

struct CashFlowCardView: View {
    let income: Double
    let expenses: Double

    private var net: Double { income - expenses }

    private var incomeWidth: CGFloat {
        guard income + expenses > 0 else { return 0.5 }
        return CGFloat(income / (income + expenses))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cash Flow")
                    .font(CrownTheme.headlineFont)
                    .foregroundStyle(Color.adaptiveNavy)
                Spacer()
                Text(Date().relativeMonthLabel)
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            // Side-by-side income vs expenses
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(CrownTheme.income)
                            .frame(width: 8, height: 8)
                        Text("Income")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    CurrencyText(
                        amount: income,
                        font: CrownTheme.headlineFont,
                        colorCoded: false
                    )
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Expenses")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Circle()
                            .fill(CrownTheme.expense)
                            .frame(width: 8, height: 8)
                    }
                    CurrencyText(
                        amount: expenses,
                        font: CrownTheme.headlineFont,
                        colorCoded: false
                    )
                }
            }

            // Proportional bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(CrownTheme.income)
                        .frame(width: max(geo.size.width * incomeWidth - 1, 4))

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(CrownTheme.expense)
                }
            }
            .frame(height: 8)

            // Net
            Divider()

            HStack {
                Text("Net")
                    .font(CrownTheme.subheadFont)
                    .foregroundStyle(.secondary)
                Spacer()
                CurrencyText(
                    amount: net,
                    font: CrownTheme.headlineFont,
                    showSign: true,
                    colorCoded: true
                )
            }
        }
        .crownCard()
    }
}

#Preview {
    CashFlowCardView(income: 5500, expenses: 3240)
        .padding()
        .background(CrownTheme.screenBackground)
}
