import Foundation
import Observation

/// ViewModel for the Budget tab.
///
/// Responsibilities:
/// - Loads budget categories and transactions for the selected month
/// - Computes per-category spending and progress toward monthly limits
/// - Handles CRUD for budget categories
///
/// Key computation:
/// `spent(for:)` is computed at query time by summing absolute values of expense
/// transactions in the selected month that match the category — this avoids storing
/// redundant `spent` values in SwiftData that could become stale.
///
/// Future extensions:
/// - Rollover balances between months (carry over unspent budget)
/// - Budget alerts / push notifications at 80% and 100% thresholds
/// - Flex budgeting mode (Fixed / Flexible / Non-Monthly groupings)
@Observable
final class BudgetViewModel {

    // MARK: - Dependencies
    private let budgetRepo:      any BudgetRepositoryProtocol
    private let transactionRepo: any TransactionRepositoryProtocol

    // MARK: - State
    var selectedMonth: Date = Date()
    var budgetCategories: [BudgetCategory] = []
    var monthTransactions: [Transaction] = []
    var isLoading: Bool = false
    var showAddCategory: Bool = false

    // MARK: - Computed Aggregates

    var totalBudgeted: Double {
        budgetCategories.reduce(0) { $0 + $1.monthlyLimit }
    }

    var totalSpent: Double {
        budgetCategories.reduce(0) { total, category in total + spent(for: category) }
    }

    var remainingBudget: Double {
        totalBudgeted - totalSpent
    }

    var isOverBudget: Bool {
        totalSpent > totalBudgeted
    }

    // MARK: - Per-category helpers

    /// Returns total absolute spending for a given category in the selected month.
    func spent(for budgetCategory: BudgetCategory) -> Double {
        monthTransactions
            .filter { $0.category == budgetCategory.category && $0.isExpense }
            .reduce(0) { $0 + $1.absoluteAmount }
    }

    /// Returns the progress ratio (0.0–1.0+) for a budget category.
    /// Values > 1.0 mean over-budget.
    func progress(for budgetCategory: BudgetCategory) -> Double {
        guard budgetCategory.monthlyLimit > 0 else { return 0 }
        return spent(for: budgetCategory) / budgetCategory.monthlyLimit
    }

    /// Returns transactions for a specific budget category in the selected month.
    func transactions(for budgetCategory: BudgetCategory) -> [Transaction] {
        monthTransactions
            .filter { $0.category == budgetCategory.category }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Init

    init(
        budgetRepo:      any BudgetRepositoryProtocol,
        transactionRepo: any TransactionRepositoryProtocol
    ) {
        self.budgetRepo      = budgetRepo
        self.transactionRepo = transactionRepo
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true
        budgetCategories = budgetRepo.fetchAllCategories()
        monthTransactions = transactionRepo.fetchForMonth(
            month: selectedMonth.month,
            year:  selectedMonth.year
        )
        isLoading = false
    }

    func navigateMonth(by offset: Int) {
        selectedMonth = selectedMonth.monthOffset(by: offset)
        loadData()
    }

    // MARK: - Mutations

    func addCategory(name: String, emoji: String, limit: Double, category: TransactionCategory) {
        let newCat = BudgetCategory(name: name, emoji: emoji, monthlyLimit: limit, category: category)
        budgetRepo.insertCategory(newCat)
        budgetRepo.save()
        budgetCategories = budgetRepo.fetchAllCategories()
    }

    func deleteCategory(_ category: BudgetCategory) {
        budgetRepo.deleteCategory(category)
        budgetRepo.save()
        budgetCategories = budgetRepo.fetchAllCategories()
    }

    func updateLimit(for category: BudgetCategory, newLimit: Double) {
        category.monthlyLimit = newLimit
        budgetRepo.save()
    }
}
