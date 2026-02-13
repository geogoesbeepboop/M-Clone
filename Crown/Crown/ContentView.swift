//
//  MainTabView.swift
//  Crown
//
//  Created by George Andrade-Munoz on 2/12/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var showChat = false
    @State private var selectedTab: CrownTab = .dashboard

    @Environment(\.accountRepository)     private var accountRepo
    @Environment(\.transactionRepository) private var transactionRepo
    @Environment(\.budgetRepository)      private var budgetRepo
    @Environment(\.netWorthRepository)    private var netWorthRepo
    @Environment(\.modelContext)          private var modelContext

    @State private var chatViewModel: ChatViewModel?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "house.fill", value: .dashboard) {
                NavigationStack {
                    DashboardView()
                }
            }

            Tab("Accounts", systemImage: "building.columns.fill", value: .accounts) {
                NavigationStack {
                    AccountsView()
                }
            }

            Tab("Transactions", systemImage: "list.bullet.rectangle", value: .transactions) {
                NavigationStack {
                    TransactionsListView()
                }
            }

            Tab("Cash Flow", systemImage: "arrow.up.arrow.down.circle.fill", value: .cashFlow) {
                NavigationStack {
                    CashFlowView()
                }
            }

            Tab("Budget", systemImage: "chart.pie.fill", value: .budget) {
                NavigationStack {
                    BudgetOverviewView()
                }
            }
        }
        .tint(CrownTheme.primaryBlue)
        .environment(\.showChat, $showChat)
        .environment(\.selectedTab, $selectedTab)
        .sheet(isPresented: $showChat) {
            NavigationStack {
                ChatHistoryView(viewModel: resolvedChatViewModel)
            }
        }
        .task {
            ensureChatViewModel()
        }
    }

    /// Returns the existing ViewModel or creates one on demand.
    /// This guarantees the sheet always receives a non-nil ViewModel.
    private var resolvedChatViewModel: ChatViewModel {
        if let vm = chatViewModel { return vm }
        let vm = ChatViewModel(
            accountRepo:     accountRepo,
            transactionRepo: transactionRepo,
            budgetRepo:      budgetRepo,
            netWorthRepo:    netWorthRepo,
            modelContext:    modelContext
        )
        // Schedule state update for next run loop to avoid mutating state during body
        DispatchQueue.main.async { chatViewModel = vm }
        return vm
    }

    private func ensureChatViewModel() {
        guard chatViewModel == nil else { return }
        chatViewModel = ChatViewModel(
            accountRepo:     accountRepo,
            transactionRepo: transactionRepo,
            budgetRepo:      budgetRepo,
            netWorthRepo:    netWorthRepo,
            modelContext:    modelContext
        )
    }
}

#Preview {
    MainTabView()
}
