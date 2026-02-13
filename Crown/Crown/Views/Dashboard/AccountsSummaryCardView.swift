import SwiftUI

struct AccountsSummaryCardView: View {
    let accounts: [Account]

    private var assetAccounts: [Account] { accounts.filter { $0.type.isAsset } }
    private var liabilityAccounts: [Account] { accounts.filter { !$0.type.isAsset } }
    private var totalAssets: Double { assetAccounts.reduce(0) { $0 + $1.balance } }
    private var totalLiabilities: Double { liabilityAccounts.reduce(0) { $0 + abs($1.balance) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Accounts")
                .font(CrownTheme.headlineFont)
                .foregroundStyle(Color.adaptiveNavy)
                .padding(.horizontal, CrownTheme.cardPadding)
                .padding(.top, CrownTheme.cardPadding)

            if !assetAccounts.isEmpty {
                VStack(spacing: 0) {
                    // Section label
                    Text("Banking")
                        .font(CrownTheme.caption2Font)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, CrownTheme.cardPadding)
                        .padding(.top, 10)
                        .padding(.bottom, 4)

                    ForEach(assetAccounts) { account in
                        AccountRowView(account: account)
                            .padding(.horizontal, CrownTheme.cardPadding)
                        if account.id != assetAccounts.last?.id {
                            Divider().padding(.leading, CrownTheme.cardPadding + 48)
                        }
                    }

                    HStack {
                        Text("Total Assets")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Spacer()
                        CurrencyText(amount: totalAssets, font: CrownTheme.captionFont)
                            .foregroundStyle(CrownTheme.income)
                    }
                    .padding(.horizontal, CrownTheme.cardPadding)
                    .padding(.vertical, 8)
                    .background(CrownTheme.tertiaryBackground)
                }
            }

            if !liabilityAccounts.isEmpty {
                BofASectionDivider()

                VStack(spacing: 0) {
                    Text("Credit Cards")
                        .font(CrownTheme.caption2Font)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, CrownTheme.cardPadding)
                        .padding(.top, 10)
                        .padding(.bottom, 4)

                    ForEach(liabilityAccounts) { account in
                        AccountRowView(account: account)
                            .padding(.horizontal, CrownTheme.cardPadding)
                        if account.id != liabilityAccounts.last?.id {
                            Divider().padding(.leading, CrownTheme.cardPadding + 48)
                        }
                    }

                    HStack {
                        Text("Total Liabilities")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Spacer()
                        CurrencyText(amount: totalLiabilities, font: CrownTheme.captionFont)
                            .foregroundStyle(CrownTheme.expense)
                    }
                    .padding(.horizontal, CrownTheme.cardPadding)
                    .padding(.vertical, 8)
                    .background(CrownTheme.tertiaryBackground)
                }
            }
        }
        .padding(.bottom, CrownTheme.cardPadding)
        .crownCard(padding: 0)
    }
}

private struct AccountRowView: View {
    let account: Account

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: account.type.systemImage)
                .font(.system(size: 16))
                .foregroundStyle(CrownTheme.primaryBlue)
                .frame(width: 36, height: 36)
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
        .padding(.vertical, 8)
    }
}

#Preview {
    AccountsSummaryCardView(accounts: [
        Account(name: "Advantage Checking", institution: "Bank of America", type: .checking, balance: 4832.47),
        Account(name: "Advantage Savings",  institution: "Bank of America", type: .savings,  balance: 15200),
        Account(name: "Customized Cash Rewards", institution: "Bank of America", type: .creditCard, balance: -1247.83)
    ])
    .padding()
    .background(CrownTheme.screenBackground)
}
