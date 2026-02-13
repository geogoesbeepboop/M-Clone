import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var date: Date
    var merchant: String
    var amount: Double          // negative = expense, positive = income/credit
    var category: TransactionCategory
    var isPending: Bool
    var notes: String
    var plaidTransactionId: String?

    var account: Account?

    init(
        date: Date,
        merchant: String,
        amount: Double,
        category: TransactionCategory,
        account: Account? = nil,
        isPending: Bool = false,
        notes: String = "",
        plaidTransactionId: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.merchant = merchant
        self.amount = amount
        self.category = category
        self.account = account
        self.isPending = isPending
        self.notes = notes
        self.plaidTransactionId = plaidTransactionId
    }

    /// Positive amount = money in (income, refund). Negative = money out (expense).
    var isExpense: Bool { amount < 0 }
    var isIncome: Bool { amount > 0 }

    /// Absolute value for display in expense contexts
    var absoluteAmount: Double { abs(amount) }
}
