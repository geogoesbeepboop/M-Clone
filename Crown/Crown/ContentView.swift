//
//  MainTabView.swift
//  Crown
//
//  Created by George Andrade-Munoz on 2/12/26.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") {
                NavigationStack {
                    DashboardView()
                }
            }

            Tab("Accounts", systemImage: "building.columns.fill") {
                NavigationStack {
                    AccountsView()
                }
            }

            Tab("Transactions", systemImage: "list.bullet.rectangle") {
                NavigationStack {
                    TransactionsListView()
                }
            }

            Tab("Cash Flow", systemImage: "arrow.up.arrow.down.circle.fill") {
                NavigationStack {
                    CashFlowView()
                }
            }

            Tab("Budget", systemImage: "chart.pie.fill") {
                NavigationStack {
                    BudgetOverviewView()
                }
            }

            Tab("Chat", systemImage: "bubble.left.and.bubble.right.fill") {
                NavigationStack {
                    ChatView()
                }
            }
        }
        .tint(CrownTheme.primaryBlue)
    }
}

#Preview {
    MainTabView()
}
