import SwiftUI

/// Monthly budget overview — the Budget tab's root screen.
///
/// Features:
/// - Month navigation (left/right arrows via MonthSelectorView)
/// - Summary card: total budgeted vs. total spent with color-coded indicator
/// - List of budget categories, each showing a progress bar
/// - Manage Categories toolbar button
/// - Pull-to-refresh to reload data
///
/// Navigation:
/// - Tap a category row → BudgetCategoryDetailView (transactions + donut chart)
/// - Toolbar manage button → ManageCategoriesView (add/delete categories)
struct BudgetOverviewView: View {
    @Environment(\.budgetRepository)      private var budgetRepo
    @Environment(\.transactionRepository) private var transactionRepo

    @State private var viewModel: BudgetViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if viewModel == nil {
                let vm = BudgetViewModel(budgetRepo: budgetRepo, transactionRepo: transactionRepo)
                viewModel = vm
                vm.loadData()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: BudgetViewModel) -> some View {
        ScrollView {
            VStack(spacing: CrownTheme.sectionSpacing) {
                // Month selector
                MonthSelectorView(
                    selectedMonth: Binding(
                        get: { vm.selectedMonth },
                        set: { vm.selectedMonth = $0 }
                    )
                )
                .onChange(of: vm.selectedMonth) { _, _ in
                    vm.loadData()
                }

                // Summary card
                budgetSummaryCard(vm: vm)

                // Category rows
                if vm.budgetCategories.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.pie",
                        title: "No Budget Categories",
                        message: "Tap the manage button to add budget categories.",
                        actionTitle: "Add Category"
                    ) {
                        vm.showAddCategory = true
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(vm.budgetCategories) { category in
                            NavigationLink {
                                BudgetCategoryDetailView(
                                    category: category,
                                    transactions: vm.transactions(for: category),
                                    spent: vm.spent(for: category),
                                    onUpdateLimit: { newLimit in
                                        vm.updateLimit(for: category, newLimit: newLimit)
                                    }
                                )
                            } label: {
                                BudgetCategoryRowView(
                                    category: category,
                                    spent: vm.spent(for: category),
                                    progress: vm.progress(for: category)
                                )
                                .padding(.horizontal, CrownTheme.cardPadding)
                            }
                            .buttonStyle(.plain)

                            if category.id != vm.budgetCategories.last?.id {
                                Divider().padding(.leading, CrownTheme.cardPadding)
                            }
                        }
                    }
                    .crownCard(padding: 0)
                }
            }
            .padding(.horizontal, CrownTheme.horizontalPadding)
            .padding(.bottom, CrownTheme.sectionSpacing)
        }
        .background(CrownTheme.screenBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ManageCategoriesView(viewModel: vm)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(CrownTheme.primaryBlue)
                }
            }
        }
        .refreshable {
            vm.loadData()
        }
    }

    // MARK: - Summary Card

    private func budgetSummaryCard(vm: BudgetViewModel) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text(vm.selectedMonth.monthYearString)
                    .font(CrownTheme.headlineFont)
                Spacer()
                Text(vm.isOverBudget ? "Over Budget" : "On Track")
                    .font(CrownTheme.captionFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(vm.isOverBudget ? CrownTheme.expense : CrownTheme.income)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (vm.isOverBudget ? CrownTheme.expense : CrownTheme.income).opacity(0.12)
                    )
                    .clipShape(Capsule())
            }

            // Spent vs Budgeted
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spent")
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(.secondary)
                    CurrencyText(amount: vm.totalSpent, font: CrownTheme.titleFont)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Budget")
                        .font(CrownTheme.captionFont)
                        .foregroundStyle(.secondary)
                    CurrencyText(amount: vm.totalBudgeted, font: CrownTheme.titleFont)
                }
            }

            // Overall progress bar
            ProgressBarView(
                progress: vm.totalBudgeted > 0
                    ? vm.totalSpent / vm.totalBudgeted
                    : 0,
                height: 10
            )

            // Remaining
            HStack {
                Text(vm.isOverBudget ? "Over by" : "Remaining")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                Spacer()
                CurrencyText(
                    amount: abs(vm.remainingBudget),
                    font: CrownTheme.subheadFont
                )
                .foregroundStyle(vm.isOverBudget ? CrownTheme.expense : CrownTheme.income)
            }
        }
        .crownCard()
    }
}

#Preview {
    NavigationStack { BudgetOverviewView() }
}
