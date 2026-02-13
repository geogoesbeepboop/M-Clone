import SwiftUI

struct UpcomingBillsCardView: View {
    let pendingTransactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending")
                .font(CrownTheme.headlineFont)

            if pendingTransactions.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CrownTheme.income)
                    Text("No pending transactions")
                        .font(CrownTheme.subheadFont)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(pendingTransactions.prefix(5)) { txn in
                        HStack(spacing: 12) {
                            Text(txn.category.emoji)
                                .font(.body)
                                .frame(width: 36, height: 36)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(txn.merchant)
                                    .font(CrownTheme.subheadFont)
                                Text(txn.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(CrownTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                CurrencyText(
                                    amount: txn.amount,
                                    font: CrownTheme.subheadFont,
                                    colorCoded: true
                                )
                                Text("Pending")
                                    .font(CrownTheme.caption2Font)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 8)

                        if txn.id != pendingTransactions.prefix(5).last?.id {
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
    UpcomingBillsCardView(pendingTransactions: [])
        .padding()
        .background(CrownTheme.screenBackground)
}
