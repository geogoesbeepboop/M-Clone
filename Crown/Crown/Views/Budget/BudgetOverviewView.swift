import SwiftUI

/// Monthly budget overview — the Budget tab's root screen.
///
/// Layout:
/// 1. Month selector
/// 2. Hero card: "Left to Budget" with progress bar
/// 3. Income section with total
/// 4. Expenses section with per-category rows (budget + remaining columns)
struct BudgetOverviewView: View {
    @Environment(\.budgetRepository)      private var budgetRepo
    @Environment(\.transactionRepository) private var transactionRepo
    @Environment(\.showChat)             private var showChat

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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 4) {
                    Button {
                        viewModel?.showAddCategory = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(CrownTheme.primaryBlue)
                    }

                    if let vm = viewModel {
                        NavigationLink {
                            ManageCategoriesView(viewModel: vm)
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(CrownTheme.primaryBlue)
                        }
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        viewModel?.sortAscending.toggle()
                    } label: {
                        Image(systemName: viewModel?.sortAscending == true
                            ? "arrow.up.arrow.down.circle.fill"
                            : "arrow.up.arrow.down.circle")
                            .foregroundStyle(CrownTheme.primaryBlue)
                    }

                    Button {
                        showChat.wrappedValue = true
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(CrownTheme.primaryBlue)
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showAddCategory ?? false },
            set: { viewModel?.showAddCategory = $0 }
        )) {
            if let vm = viewModel {
                AddBudgetCategoryView { name, emoji, limit, category in
                    vm.addCategory(name: name, emoji: emoji, limit: limit, category: category)
                }
            }
        }
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

                // Hero card — "Left to Budget"
                heroCard(vm: vm)

                // Income section
                incomeSection(vm: vm)

                // Expenses section
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
                    expensesSection(vm: vm)
                }
            }
            .padding(.horizontal, CrownTheme.horizontalPadding)
            .padding(.bottom, CrownTheme.sectionSpacing)
        }
        .background(CrownTheme.screenBackground)
        .refreshable {
            vm.loadData()
        }
    }

    // MARK: - Hero Card

    private func heroCard(vm: BudgetViewModel) -> some View {
        VStack(spacing: 12) {
            Text("Left to Budget")
                .font(CrownTheme.captionFont)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)

            CurrencyText(
                amount: abs(vm.remainingBudget),
                font: CrownTheme.largeCurrencyFont
            )
            .foregroundStyle(overallBudgetColor(vm: vm))

            // Overall progress bar
            ProgressBarView(
                progress: overallProgress(vm: vm),
                height: 10,
                tint: overallBudgetColor(vm: vm)
            )

            // Subtitle
            HStack {
                Text(vm.isOverBudget ? "Over budget" : "On track")
                    .font(CrownTheme.captionFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(overallBudgetColor(vm: vm))
                Spacer()
                Text("\(vm.totalSpent, format: .currency(code: "USD").precision(.fractionLength(0))) of \(vm.totalBudgeted, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .crownCard(showDivider: false)
    }

    // MARK: - Income Section

    private func incomeSection(vm: BudgetViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Text("Income")
                    .font(CrownTheme.headlineFont)
                    .foregroundStyle(Color.adaptiveNavy)
                Spacer()
                CurrencyText(amount: vm.totalIncome, font: CrownTheme.headlineFont)
                    .foregroundStyle(CrownTheme.income)
            }

            // Income summary card
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(CrownTheme.income)

                    Text("Total Income")
                        .font(CrownTheme.subheadFont)

                    Spacer()

                    CurrencyText(amount: vm.totalIncome, font: CrownTheme.subheadFont)
                }

                // Simple progress indicator (income as proportion of budget)
                if vm.totalBudgeted > 0 {
                    ProgressBarView(
                        progress: min(vm.totalIncome / vm.totalBudgeted, 1.0),
                        height: 6,
                        tint: CrownTheme.income
                    )
                }
            }
            .crownCard(showDivider: false)
        }
    }

    // MARK: - Expenses Section

    private func expensesSection(vm: BudgetViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Text("Expenses")
                    .font(CrownTheme.headlineFont)
                    .foregroundStyle(Color.adaptiveNavy)
                Spacer()
                CurrencyText(amount: vm.totalExpenses, font: CrownTheme.headlineFont)
                    .foregroundStyle(CrownTheme.expense)
            }

            // Category rows card
            VStack(spacing: 0) {
                // Column headers
                HStack {
                    Text("Category")
                        .font(CrownTheme.caption2Font)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    HStack(spacing: 24) {
                        Text("Budget")
                            .font(CrownTheme.caption2Font)
                            .foregroundStyle(.tertiary)
                            .frame(width: 70, alignment: .trailing)
                        Text("Remaining")
                            .font(CrownTheme.caption2Font)
                            .foregroundStyle(.tertiary)
                            .frame(width: 70, alignment: .trailing)
                    }
                }
                .padding(.horizontal, CrownTheme.cardPadding)
                .padding(.top, CrownTheme.cardPadding)
                .padding(.bottom, 4)

                Divider()

                // Category rows
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
                        budgetCategoryRow(vm: vm, category: category)
                    }
                    .buttonStyle(.plain)

                    if category.id != vm.budgetCategories.last?.id {
                        Divider().padding(.leading, CrownTheme.cardPadding + 36)
                    }
                }
            }
            .crownCard(padding: 0, showDivider: false)
        }
    }

    // MARK: - Budget Category Row

    private func budgetCategoryRow(vm: BudgetViewModel, category: BudgetCategory) -> some View {
        let categorySpent = vm.spent(for: category)
        let categoryRemaining = vm.remaining(for: category)
        let categoryProgress = vm.progress(for: category)
        let isOver = categoryProgress > 1.0

        return VStack(spacing: 6) {
            HStack {
                // Emoji + name
                HStack(spacing: 8) {
                    Text(category.emoji)
                        .font(.body)
                    Text(category.name)
                        .font(CrownTheme.subheadFont)
                }

                Spacer()

                // Budget + Remaining columns
                HStack(spacing: 24) {
                    CurrencyText(
                        amount: category.monthlyLimit,
                        font: CrownTheme.captionFont,
                        colorCoded: false
                    )
                    .frame(width: 70, alignment: .trailing)

                    CurrencyText(
                        amount: abs(categoryRemaining),
                        font: CrownTheme.captionFont,
                        colorCoded: false
                    )
                    .foregroundStyle(CrownTheme.budgetColor(for: categoryProgress))
                    .frame(width: 70, alignment: .trailing)
                }
            }

            // Progress bar
            ProgressBarView(
                progress: categoryProgress,
                tint: CrownTheme.budgetColor(for: categoryProgress)
            )

            // Spent label
            HStack {
                Text("\(categorySpent, format: .currency(code: "USD").precision(.fractionLength(0))) spent")
                    .font(CrownTheme.caption2Font)
                    .foregroundStyle(.secondary)
                Spacer()
                if isOver {
                    Text("Over by \(abs(categoryRemaining), format: .currency(code: "USD").precision(.fractionLength(0)))")
                        .font(CrownTheme.caption2Font)
                        .foregroundStyle(CrownTheme.budgetRed)
                }
            }
        }
        .padding(.horizontal, CrownTheme.cardPadding)
        .padding(.vertical, 10)
    }
    // MARK: - Helpers

    private func overallProgress(vm: BudgetViewModel) -> Double {
        vm.totalBudgeted > 0 ? vm.totalSpent / vm.totalBudgeted : 0
    }

    private func overallBudgetColor(vm: BudgetViewModel) -> Color {
        CrownTheme.budgetColor(for: overallProgress(vm: vm))
    }
}

#Preview {
    NavigationStack { BudgetOverviewView() }
}
