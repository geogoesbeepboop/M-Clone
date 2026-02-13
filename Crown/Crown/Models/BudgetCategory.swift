import Foundation
import SwiftData

@Model
final class BudgetCategory {
    var id: UUID
    var name: String
    var emoji: String
    var monthlyLimit: Double
    var category: TransactionCategory

    @Relationship(deleteRule: .cascade, inverse: \Budget.budgetCategory)
    var budgets: [Budget]

    init(
        name: String,
        emoji: String,
        monthlyLimit: Double,
        category: TransactionCategory
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.monthlyLimit = monthlyLimit
        self.category = category
        self.budgets = []
    }
}
