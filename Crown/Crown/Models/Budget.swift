import Foundation
import SwiftData

@Model
final class Budget {
    var id: UUID
    var month: Int      // 1 – 12
    var year: Int
    var limit: Double

    var budgetCategory: BudgetCategory?

    init(month: Int, year: Int, limit: Double, budgetCategory: BudgetCategory? = nil) {
        self.id = UUID()
        self.month = month
        self.year = year
        self.limit = limit
        self.budgetCategory = budgetCategory
    }
}
