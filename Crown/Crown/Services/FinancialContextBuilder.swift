import Foundation

/// Builds the system prompt injected into every Claude conversation.
///
/// Pulls live data from repositories so Claude's answers are grounded in the
/// user's actual accounts, budget, and recent transactions — not fabricated.
struct FinancialContextBuilder {

    private let accountRepo:     AccountRepositoryProtocol
    private let transactionRepo: TransactionRepositoryProtocol
    private let budgetRepo:      BudgetRepositoryProtocol
    private let netWorthRepo:    NetWorthRepositoryProtocol

    init(
        accountRepo:     AccountRepositoryProtocol,
        transactionRepo: TransactionRepositoryProtocol,
        budgetRepo:      BudgetRepositoryProtocol,
        netWorthRepo:    NetWorthRepositoryProtocol
    ) {
        self.accountRepo     = accountRepo
        self.transactionRepo = transactionRepo
        self.budgetRepo      = budgetRepo
        self.netWorthRepo    = netWorthRepo
    }

    /// Returns a detailed system prompt with the user's current financial snapshot.
    func buildSystemPrompt() -> String {
        var parts: [String] = []

        parts.append(baseInstruction)
        parts.append(accountsSummary())
        parts.append(netWorthSummary())
        parts.append(cashFlowSummary())
        parts.append(spendingByCategorySummary())
        parts.append(budgetSummary())
        parts.append(recentTransactionsSummary())

        return parts.joined(separator: "\n\n")
    }

    // MARK: - Sections

    private var baseInstruction: String {
        """
        You are a helpful personal finance assistant for the Crown app. \
        Your role is to give concise, actionable financial advice based on the user's real data provided below. \
        Always use specific numbers from the data. \
        Never fabricate transactions, balances, or statistics not present in the data. \
        Keep answers focused and under 200 words unless a detailed breakdown is requested. \
        Format currency as US dollars. Today's date is \(Date().formatted(.dateTime.month().day().year())).
        """
    }

    private func accountsSummary() -> String {
        let accounts = accountRepo.fetchVisible()
        guard !accounts.isEmpty else { return "ACCOUNTS: None connected." }

        let lines = accounts.map { account in
            let sign = account.balance < 0 ? "-$\(abs(account.balance).formatted(.number.precision(.fractionLength(2))))"
                                           : "$\(account.balance.formatted(.number.precision(.fractionLength(2))))"
            return "  - \(account.name) (\(account.institution), \(account.type.displayName)): \(sign)"
        }
        return "ACCOUNTS:\n" + lines.joined(separator: "\n")
    }

    private func netWorthSummary() -> String {
        let accounts    = accountRepo.fetchVisible()
        let assets      = accounts.filter { $0.type.isAsset }.reduce(0) { $0 + $1.balance }
        let liabilities = accounts.filter { !$0.type.isAsset }.reduce(0) { $0 + abs($1.balance) }
        let netWorth    = assets - liabilities

        var section = """
        NET WORTH:
          Total Assets:      $\(assets.formatted(.number.precision(.fractionLength(0))))
          Total Liabilities: $\(liabilities.formatted(.number.precision(.fractionLength(0))))
          Net Worth:         $\(netWorth.formatted(.number.precision(.fractionLength(0))))
        """

        // Month-over-month change
        let snapshots = netWorthRepo.fetchForPastMonths(2)
        if snapshots.count >= 2 {
            let change = snapshots[0].netWorth - snapshots[1].netWorth
            let sign   = change >= 0 ? "+" : ""
            section += "\n  MoM Change: \(sign)$\(change.formatted(.number.precision(.fractionLength(0))))"
        }
        return section
    }

    private func cashFlowSummary() -> String {
        let now    = Date()
        let cal    = Calendar.current
        let month  = cal.component(.month, from: now)
        let year   = cal.component(.year, from: now)
        let txns   = transactionRepo.fetchForMonth(month: month, year: year)

        let income   = txns.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        let expenses = txns.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
        let net      = income - expenses

        return """
        CASH FLOW (this month):
          Income:   $\(income.formatted(.number.precision(.fractionLength(0))))
          Expenses: $\(expenses.formatted(.number.precision(.fractionLength(0))))
          Net:      \(net >= 0 ? "+" : "")$\(net.formatted(.number.precision(.fractionLength(0))))
        """
    }

    private func spendingByCategorySummary() -> String {
        let now   = Date()
        let cal   = Calendar.current
        let month = cal.component(.month, from: now)
        let year  = cal.component(.year, from: now)
        let txns  = transactionRepo.fetchForMonth(month: month, year: year)
            .filter { $0.amount < 0 }

        guard !txns.isEmpty else { return "SPENDING BY CATEGORY (this month): No expenses recorded." }

        let grouped = Dictionary(grouping: txns, by: { $0.category })
        let sorted  = grouped
            .map { (category: $0.key, total: $0.value.reduce(0) { $0 + abs($1.amount) }) }
            .sorted { $0.total > $1.total }
            .prefix(8)

        let lines = sorted.map { item in
            "  - \(item.category.emoji) \(item.category.rawValue): $\(item.total.formatted(.number.precision(.fractionLength(0))))"
        }
        return "SPENDING BY CATEGORY (this month):\n" + lines.joined(separator: "\n")
    }

    private func budgetSummary() -> String {
        let categories = budgetRepo.fetchAllCategories()
        guard !categories.isEmpty else { return "BUDGET: No budget categories configured." }

        let now   = Date()
        let cal   = Calendar.current
        let month = cal.component(.month, from: now)
        let year  = cal.component(.year, from: now)

        var lines: [String] = []
        for cat in categories {
            let txns  = transactionRepo.fetchForCategory(cat.category, month: month, year: year)
            let spent = txns.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
            let limit = cat.monthlyLimit
            let pct   = limit > 0 ? Int((spent / limit) * 100) : 0
            let flag  = spent > limit ? " ⚠️ OVER BUDGET" : ""
            lines.append("  - \(cat.emoji) \(cat.name): $\(Int(spent)) of $\(Int(limit)) (\(pct)%)\(flag)")
        }
        return "BUDGET (this month):\n" + lines.joined(separator: "\n")
    }

    private func recentTransactionsSummary() -> String {
        let recent = transactionRepo.fetchAll(limit: 20)
        guard !recent.isEmpty else { return "RECENT TRANSACTIONS: None." }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let lines = recent.map { tx in
            let amtStr = tx.amount >= 0
                ? "+$\(tx.amount.formatted(.number.precision(.fractionLength(2))))"
                : "-$\(abs(tx.amount).formatted(.number.precision(.fractionLength(2))))"
            return "  - \(formatter.string(from: tx.date)) \(tx.merchant) \(amtStr) [\(tx.category.rawValue)]"
        }
        return "RECENT TRANSACTIONS (last 20):\n" + lines.joined(separator: "\n")
    }
}
