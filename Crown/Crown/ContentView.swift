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
                ChatView()
            }
        }
    }
}

#Preview {
    MainTabView()
}
