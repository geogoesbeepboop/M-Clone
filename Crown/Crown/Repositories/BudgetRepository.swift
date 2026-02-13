import Foundation
import SwiftData

// MARK: - Protocol

protocol BudgetRepositoryProtocol {
    func fetchAllCategories() -> [BudgetCategory]
    func fetchBudget(for category: BudgetCategory, month: Int, year: Int) -> Budget?
    func insertCategory(_ category: BudgetCategory)
    func deleteCategory(_ category: BudgetCategory)
    func insertBudget(_ budget: Budget)
    func save()
}

// MARK: - SwiftData Implementation

final class BudgetRepository: BudgetRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllCategories() -> [BudgetCategory] {
        let descriptor = FetchDescriptor<BudgetCategory>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchBudget(for category: BudgetCategory, month: Int, year: Int) -> Budget? {
        category.budgets.first { $0.month == month && $0.year == year }
    }

    func insertCategory(_ category: BudgetCategory) {
        modelContext.insert(category)
    }

    func deleteCategory(_ category: BudgetCategory) {
        modelContext.delete(category)
    }

    func insertBudget(_ budget: Budget) {
        modelContext.insert(budget)
    }

    func save() {
        try? modelContext.save()
    }
}
