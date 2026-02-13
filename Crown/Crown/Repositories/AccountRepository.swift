import Foundation
import SwiftData

// MARK: - Protocol

protocol AccountRepositoryProtocol {
    func fetchAll() -> [Account]
    func fetchVisible() -> [Account]
    func fetchAssets() -> [Account]
    func fetchLiabilities() -> [Account]
    func fetchByPlaidAccountId(_ plaidId: String) -> Account?
    func insert(_ account: Account)
    func delete(_ account: Account)
    func save()
}

// MARK: - SwiftData Implementation

final class AccountRepository: AccountRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchVisible() -> [Account] {
        let visible = fetchAll().filter { !$0.isHidden }
        return filterByDataMode(visible)
    }

    /// Filters accounts based on the current data mode setting.
    /// - Mock ON: show only mock accounts (no plaidAccountId)
    /// - Mock OFF: show only Plaid accounts; fall back to all if no Plaid accounts exist
    private func filterByDataMode(_ accounts: [Account]) -> [Account] {
        if AppConfig.useMockData {
            return accounts.filter { $0.plaidAccountId == nil }
        } else {
            let plaid = accounts.filter { $0.plaidAccountId != nil }
            return plaid.isEmpty ? accounts : plaid
        }
    }

    func fetchAssets() -> [Account] {
        fetchVisible().filter { $0.type.isAsset }
    }

    func fetchLiabilities() -> [Account] {
        fetchVisible().filter { !$0.type.isAsset }
    }

    func fetchByPlaidAccountId(_ plaidId: String) -> Account? {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.plaidAccountId == plaidId }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func insert(_ account: Account) {
        modelContext.insert(account)
    }

    func delete(_ account: Account) {
        modelContext.delete(account)
    }

    func save() {
        try? modelContext.save()
    }
}
