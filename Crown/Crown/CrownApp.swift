//
//  CrownApp.swift
//  Crown
//
//  Created by George Andrade-Munoz on 2/12/26.
//

import SwiftUI
import SwiftData

@main
struct CrownApp: App {

    // MARK: - Appearance

    @AppStorage("crownAppearanceMode") private var appearanceMode: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": .light
        case "dark":  .dark
        default:      nil
        }
    }

    // MARK: - SwiftData ModelContainer

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            Transaction.self,
            BudgetCategory.self,
            Budget.self,
            NetWorthSnapshot.self,
            ChatMessage.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.accountRepository,
                    AccountRepository(modelContext: sharedModelContainer.mainContext))
                .environment(\.transactionRepository,
                    TransactionRepository(modelContext: sharedModelContainer.mainContext))
                .environment(\.budgetRepository,
                    BudgetRepository(modelContext: sharedModelContainer.mainContext))
                .environment(\.netWorthRepository,
                    NetWorthRepository(modelContext: sharedModelContainer.mainContext))
                .preferredColorScheme(preferredColorScheme)
                .onAppear {
                    if AppConfig.useMockData {
                        MockDataService.seedIfNeeded(context: sharedModelContainer.mainContext)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
