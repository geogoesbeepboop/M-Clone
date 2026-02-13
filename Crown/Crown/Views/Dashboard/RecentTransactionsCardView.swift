import SwiftUI

/// Dashboard card showing the 4 most recent transactions.
///
/// Matches the BofA dashboard "Transactions" card with "Most recent" subtitle,
/// emoji icons, merchant names, amounts, and "P" pending badges.
struct RecentTransactionsCardView: View {
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Transactions")
                    .font(CrownTheme.headlineFont)
                Spacer()
                Image(systemName: "ellipsis")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            // Subtitle
            HStack(spacing: 4) {
                Text("Most recent")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }

            if transactions.isEmpty {
                Text("No transactions yet.")
                    .font(CrownTheme.subheadFont)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(transactions.prefix(4)) { txn in
                        HStack(spacing: 12) {
                            // Category emoji
                            Text(txn.category.emoji)
                                .font(.body)
                                .frame(width: 36, height: 36)
                                .background(Color(.secondarySystemFill))
                                .clipShape(Circle())

                            // Merchant
                            Text(txn.merchant)
                                .font(CrownTheme.subheadFont)
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            // Pending badge + amount
                            HStack(spacing: 6) {
                                if txn.isPending {
                                    Text("P")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 18, height: 18)
                                        .background(Color(.systemGray3))
                                        .clipShape(Circle())
                                }
                                CurrencyText(
                                    amount: txn.amount,
                                    font: CrownTheme.subheadFont,
                                    showAbsoluteValue: true
                                )
                            }
                        }
                        .padding(.vertical, 8)

                        if txn.id != transactions.prefix(4).last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
        }
        .crownCard()
    }
}

#Preview {
    RecentTransactionsCardView(transactions: [])
        .padding()
        .background(CrownTheme.screenBackground)
}
