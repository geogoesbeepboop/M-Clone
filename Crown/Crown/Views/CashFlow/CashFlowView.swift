import SwiftUI
import Charts

/// Cash Flow tab — monthly income vs expenses summary with 6-month trend chart.
struct CashFlowView: View {
    @Environment(\.transactionRepository) private var transactionRepo
    @Environment(\.showChat)             private var showChat

    @State private var viewModel: CashFlowViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Cash Flow")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showChat.wrappedValue = true
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(CrownTheme.primaryBlue)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = CashFlowViewModel(transactionRepo: transactionRepo)
                viewModel = vm
                vm.loadData()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: CashFlowViewModel) -> some View {
        ScrollView {
            VStack(spacing: CrownTheme.sectionSpacing) {
                // Month navigator
                MonthSelectorView(selectedMonth: Binding(
                    get: { vm.selectedMonth },
                    set: { vm.selectedMonth = $0 }
                ))

                // Monthly summary card
                summaryCard(vm: vm)

                // 6-month chart
                if !vm.cashFlowByMonth.isEmpty {
                    chartCard(vm: vm)
                }

                // Monthly breakdown table
                if !vm.cashFlowByMonth.isEmpty {
                    breakdownTable(vm: vm)
                }
            }
            .padding(.horizontal, CrownTheme.horizontalPadding)
            .padding(.bottom, CrownTheme.sectionSpacing)
        }
        .background(CrownTheme.screenBackground)
        .refreshable { vm.refresh() }
    }

    // MARK: - Summary Card

    private func summaryCard(vm: CashFlowViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cash Flow")
                .font(CrownTheme.headlineFont)
                .foregroundStyle(Color.adaptiveNavy)

            // Side-by-side income vs expenses
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(CrownTheme.income)
                            .frame(width: 8, height: 8)
                        Text("Income")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    CurrencyText(amount: vm.monthlyIncome, font: CrownTheme.headlineFont, colorCoded: false)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Expenses")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                        Circle()
                            .fill(CrownTheme.expense)
                            .frame(width: 8, height: 8)
                    }
                    CurrencyText(amount: vm.monthlyExpenses, font: CrownTheme.headlineFont, colorCoded: false)
                }
            }

            // Proportional bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(CrownTheme.income)
                        .frame(width: max(geo.size.width * vm.incomeRatio - 1, 4))
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(CrownTheme.expense)
                }
            }
            .frame(height: 8)

            // Net
            Divider()

            HStack {
                Text("Net")
                    .font(CrownTheme.subheadFont)
                    .foregroundStyle(.secondary)
                Spacer()
                CurrencyText(amount: vm.netCashFlow, font: CrownTheme.headlineFont, showSign: true, colorCoded: true)
            }
        }
        .crownCard()
    }

    // MARK: - Chart Card

    private func chartCard(vm: CashFlowViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Trend")
                .font(CrownTheme.headlineFont)
                .foregroundStyle(Color.adaptiveNavy)

            Chart(vm.cashFlowByMonth) { item in
                BarMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Income", item.income),
                    width: .ratio(0.4)
                )
                .foregroundStyle(CrownTheme.income.gradient)
                .position(by: .value("Type", "Income"))
                .cornerRadius(4)

                BarMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Expenses", item.expenses),
                    width: .ratio(0.4)
                )
                .foregroundStyle(CrownTheme.expense.gradient)
                .position(by: .value("Type", "Expenses"))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(CrownTheme.captionFont)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v, format: .currency(code: "USD").precision(.fractionLength(0)))
                                .font(CrownTheme.caption2Font)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.secondary.opacity(0.3))
                }
            }
            .frame(height: 220)

            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(CrownTheme.income).frame(width: 10, height: 10)
                    Text("Income").font(CrownTheme.captionFont).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(CrownTheme.expense).frame(width: 10, height: 10)
                    Text("Expenses").font(CrownTheme.captionFont).foregroundStyle(.secondary)
                }
            }
        }
        .crownCard()
    }

    // MARK: - Breakdown Table

    private func breakdownTable(vm: CashFlowViewModel) -> some View {
        VStack(spacing: 0) {
            ForEach(vm.cashFlowByMonth.reversed()) { item in
                HStack {
                    Text(item.month.shortMonthYearString)
                        .font(CrownTheme.subheadFont)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        CurrencyText(amount: item.net, font: CrownTheme.subheadFont, showSign: true, colorCoded: true)
                        Text("In: \(item.income, format: .currency(code: "USD").precision(.fractionLength(0)))  Out: \(item.expenses, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            .font(CrownTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, CrownTheme.cardPadding)
                .padding(.vertical, 10)

                if item.id != vm.cashFlowByMonth.reversed().last?.id {
                    Divider().padding(.leading, CrownTheme.cardPadding)
                }
            }
        }
        .crownCard(padding: 0)
    }
}

#Preview {
    NavigationStack { CashFlowView() }
}
