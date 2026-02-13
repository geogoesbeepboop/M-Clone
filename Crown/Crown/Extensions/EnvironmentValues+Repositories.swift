import SwiftUI
import SwiftData

// MARK: - Private default instances (fail-safe placeholders)
// These are only used if the environment value was never injected.
// In practice, CrownApp always injects real implementations before any view appears.

private struct FallbackModelContext {
    static let context: ModelContext = {
        let schema = Schema([
            Account.self, Transaction.self, BudgetCategory.self,
            Budget.self, NetWorthSnapshot.self, ChatMessage.self,
            ChatSession.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }()
}

// MARK: - Environment Keys

private struct AccountRepositoryKey: EnvironmentKey {
    static let defaultValue: any AccountRepositoryProtocol =
        AccountRepository(modelContext: FallbackModelContext.context)
}

private struct TransactionRepositoryKey: EnvironmentKey {
    static let defaultValue: any TransactionRepositoryProtocol =
        TransactionRepository(modelContext: FallbackModelContext.context)
}

private struct BudgetRepositoryKey: EnvironmentKey {
    static let defaultValue: any BudgetRepositoryProtocol =
        BudgetRepository(modelContext: FallbackModelContext.context)
}

private struct NetWorthRepositoryKey: EnvironmentKey {
    static let defaultValue: any NetWorthRepositoryProtocol =
        NetWorthRepository(modelContext: FallbackModelContext.context)
}

// MARK: - EnvironmentValues Extensions

extension EnvironmentValues {
    var accountRepository: any AccountRepositoryProtocol {
        get { self[AccountRepositoryKey.self] }
        set { self[AccountRepositoryKey.self] = newValue }
    }

    var transactionRepository: any TransactionRepositoryProtocol {
        get { self[TransactionRepositoryKey.self] }
        set { self[TransactionRepositoryKey.self] = newValue }
    }

    var budgetRepository: any BudgetRepositoryProtocol {
        get { self[BudgetRepositoryKey.self] }
        set { self[BudgetRepositoryKey.self] = newValue }
    }

    var netWorthRepository: any NetWorthRepositoryProtocol {
        get { self[NetWorthRepositoryKey.self] }
        set { self[NetWorthRepositoryKey.self] = newValue }
    }
}
