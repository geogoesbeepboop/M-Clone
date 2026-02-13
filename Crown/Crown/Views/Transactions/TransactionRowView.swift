import SwiftUI

/// A single row in the transactions list.
///
/// Layout: [emoji circle] [merchant + category/pending] [spacer] [amount]
///
/// Color coding:
/// - Income / credits: green
/// - Expenses: red (default for negative amounts)
/// - Pending badge: orange label below merchant name
struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category emoji badge
            Text(transaction.category.emoji)
                .font(.body)
                .frame(width: 40, height: 40)
                .background(Color.adaptiveLightBlue)
                .clipShape(Circle())

            // Merchant + meta
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant)
                    .font(CrownTheme.bodyFont)
                    .lineLimit(1)

                if transaction.isPending {
                    Text("Pending")
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(.orange)
                } else {
                    Text(transaction.category.rawValue)
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                CurrencyText(
                    amount: transaction.amount,
                    font: CrownTheme.headlineFont,
                    colorCoded: true
                )
                if let accountName = transaction.account?.name {
                    Text(accountName)
                        .font(CrownTheme.caption2Font)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    let txn = Transaction(
        date: Date(),
        merchant: "Whole Foods Market",
        amount: -84.32,
        category: .groceries,
        isPending: true
    )
    return List {
        TransactionRowView(transaction: txn)
    }
}
