import SwiftUI

/// A labelled section showing a list of accounts with their balances and a subtotal.
/// Used in NetWorthView for the Assets and Liabilities sections.
struct AssetsLiabilitiesListView: View {
    let title: String
    let accounts: [Account]
    let total: Double
    let isLiability: Bool

    init(title: String, accounts: [Account], total: Double, isLiability: Bool = false) {
        self.title = title
        self.accounts = accounts
        self.total = total
        self.isLiability = isLiability
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text(title)
                    .font(CrownTheme.headlineFont)
                Spacer()
                CurrencyText(
                    amount: total,
                    font: CrownTheme.headlineFont,
                    colorCoded: false
                )
                .foregroundStyle(isLiability ? CrownTheme.expense : CrownTheme.income)
            }
            .padding(.horizontal, CrownTheme.cardPadding)
            .padding(.vertical, 12)

            Divider()

            ForEach(accounts) { account in
                HStack(spacing: 12) {
                    Image(systemName: account.type.systemImage)
                        .font(.system(size: 15))
                        .foregroundStyle(CrownTheme.primaryBlue)
                        .frame(width: 34, height: 34)
                        .background(CrownTheme.lightBlue)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                            .font(CrownTheme.subheadFont)
                        Text(account.institution)
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    CurrencyText(
                        amount: account.balance,
                        font: CrownTheme.subheadFont
                    )
                }
                .padding(.horizontal, CrownTheme.cardPadding)
                .padding(.vertical, 10)

                if account.id != accounts.last?.id {
                    Divider().padding(.leading, CrownTheme.cardPadding + 46)
                }
            }
        }
        .crownCard(padding: 0)
    }
}
