import Foundation
import SwiftData

// MARK: - Protocol

protocol NetWorthRepositoryProtocol {
    func fetchAll() -> [NetWorthSnapshot]
    func fetchLatest() -> NetWorthSnapshot?
    func fetchForPastMonths(_ months: Int) -> [NetWorthSnapshot]
    func insert(_ snapshot: NetWorthSnapshot)
    func save()
}

// MARK: - SwiftData Implementation

final class NetWorthRepository: NetWorthRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() -> [NetWorthSnapshot] {
        let descriptor = FetchDescriptor<NetWorthSnapshot>(
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchLatest() -> NetWorthSnapshot? {
        var descriptor = FetchDescriptor<NetWorthSnapshot>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func fetchForPastMonths(_ months: Int) -> [NetWorthSnapshot] {
        let cutoff = Calendar.current.date(
            byAdding: .month, value: -months, to: Date()
        ) ?? Date()
        let descriptor = FetchDescriptor<NetWorthSnapshot>(
            predicate: #Predicate { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func insert(_ snapshot: NetWorthSnapshot) {
        modelContext.insert(snapshot)
    }

    func save() {
        try? modelContext.save()
    }
}
