import Foundation
import SwiftData

/// Seeds SwiftData with realistic demo data so every screen looks great out of the box.
/// This service is idempotent — it checks if data already exists before inserting anything.
struct MockDataService {

    // MARK: - Entry point

    static func seedIfNeeded(context: ModelContext) {
        // Check specifically for mock accounts (those without a Plaid ID).
        // This allows seeding even when Plaid accounts exist, so both
        // data sources coexist and repo-level filtering selects the right one.
        let descriptor = FetchDescriptor<Account>()
        let allAccounts = (try? context.fetch(descriptor)) ?? []
        let hasMockAccounts = allAccounts.contains { $0.plaidAccountId == nil && !$0.isHidden }
        guard !hasMockAccounts else { return }

        let accounts = createAccounts(context: context)
        createTransactions(context: context, accounts: accounts)

        // Budget categories are app-level config — only seed if none exist
        let budgetDescriptor = FetchDescriptor<BudgetCategory>()
        if (try? context.fetchCount(budgetDescriptor)) ?? 0 == 0 {
            createBudgetCategories(context: context)
        }

        // Net worth snapshots — only seed if none exist
        let snapshotDescriptor = FetchDescriptor<NetWorthSnapshot>()
        if (try? context.fetchCount(snapshotDescriptor)) ?? 0 == 0 {
            createNetWorthSnapshots(context: context)
        }

        try? context.save()
    }

    // MARK: - Accounts

    private static func createAccounts(context: ModelContext) -> (
        checking: Account,
        savings: Account,
        creditCard: Account,
        investment: Account
    ) {
        let checking = Account(
            name: "Advantage Checking",
            institution: "Bank of America",
            type: .checking,
            balance: 4_832.47
        )
        let savings = Account(
            name: "Advantage Savings",
            institution: "Bank of America",
            type: .savings,
            balance: 15_200.00
        )
        let creditCard = Account(
            name: "Customized Cash Rewards",
            institution: "Bank of America",
            type: .creditCard,
            balance: -1_247.83
        )
        let investment = Account(
            name: "Individual Brokerage",
            institution: "Merrill Edge",
            type: .investment,
            balance: 42_500.00
        )

        [checking, savings, creditCard, investment].forEach { context.insert($0) }

        return (checking, savings, creditCard, investment)
    }

    // MARK: - Transactions

    private static func createTransactions(
        context: ModelContext,
        accounts: (checking: Account, savings: Account, creditCard: Account, investment: Account)
    ) {
        let calendar = Calendar.current
        let today = Date()

        // Generate ~100 transactions spread across the past 90 days
        for dayOffset in 0..<90 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // 2-4 transactions per day (0-1 on weekends)
            let isWeekend = calendar.isDateInWeekend(day)
            let count = isWeekend ? Int.random(in: 0...1) : Int.random(in: 1...3)

            for _ in 0..<count {
                let txn = randomTransaction(on: day, accounts: accounts)
                context.insert(txn)
            }
        }

        // Monthly income — paycheck on the 1st and 15th of each month
        for monthOffset in 0...2 {
            guard let baseMonth = calendar.date(byAdding: .month, value: -monthOffset, to: today) else { continue }

            for payDay in [1, 15] {
                var components = calendar.dateComponents([.year, .month], from: baseMonth)
                components.day = payDay
                if let paydayDate = calendar.date(from: components), paydayDate <= today {
                    let paycheck = Transaction(
                        date: paydayDate,
                        merchant: "Acme Corporation",
                        amount: 2_750.00,
                        category: .income,
                        account: accounts.checking,
                        isPending: false,
                        notes: "Direct Deposit"
                    )
                    context.insert(paycheck)
                }
            }
        }

        // A couple of pending transactions for realism
        let pendingDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let pending1 = Transaction(
            date: pendingDate,
            merchant: "Whole Foods Market",
            amount: -64.32,
            category: .groceries,
            account: accounts.creditCard,
            isPending: true
        )
        let pending2 = Transaction(
            date: today,
            merchant: "Netflix",
            amount: -15.49,
            category: .subscriptions,
            account: accounts.creditCard,
            isPending: true
        )
        context.insert(pending1)
        context.insert(pending2)
    }

    private static func randomTransaction(
        on day: Date,
        accounts: (checking: Account, savings: Account, creditCard: Account, investment: Account)
    ) -> Transaction {
        let (category, merchant, amount) = randomTransactionDetails()
        let account: Account = category == .income ? accounts.checking : accounts.creditCard
        let randomSeconds = TimeInterval(Int.random(in: 0..<86400))
        let date = day.addingTimeInterval(randomSeconds)

        return Transaction(
            date: date,
            merchant: merchant,
            amount: amount,
            category: category,
            account: account,
            isPending: false
        )
    }

    private static func randomTransactionDetails() -> (TransactionCategory, String, Double) {
        let pool: [(TransactionCategory, [(String, ClosedRange<Double>)])] = [
            (.groceries, [
                ("Whole Foods Market",  35...120),
                ("Trader Joe's",        25...85),
                ("Publix",              40...130),
                ("Kroger",              30...100),
                ("Costco",              60...250)
            ]),
            (.dining, [
                ("Chipotle",            10...18),
                ("Starbucks",           5...12),
                ("McDonald's",          8...15),
                ("Panera Bread",        12...20),
                ("DoorDash",            25...55),
                ("Uber Eats",           20...50),
                ("The Capital Grille",  60...180)
            ]),
            (.transportation, [
                ("Shell Gas Station",   40...90),
                ("BP",                  35...85),
                ("Uber",                12...40),
                ("Lyft",                10...35),
                ("EZ Pass",             15...50),
                ("MTA Metro Card",      33...33)
            ]),
            (.entertainment, [
                ("AMC Theaters",        15...35),
                ("Fandango",            12...30),
                ("Ticketmaster",        45...200),
                ("Xbox Game Pass",      15...15),
                ("Steam",               10...60)
            ]),
            (.shopping, [
                ("Amazon",              15...150),
                ("Target",              20...100),
                ("Best Buy",            30...500),
                ("Nike",                60...200),
                ("Apple",               10...1200),
                ("Zara",                40...150)
            ]),
            (.utilities, [
                ("Con Edison",          80...160),
                ("National Grid",       50...120),
                ("Verizon",             80...110),
                ("Comcast",             90...130),
                ("T-Mobile",            70...110)
            ]),
            (.healthcare, [
                ("CVS Pharmacy",        15...80),
                ("Walgreens",           10...60),
                ("LabCorp",             25...150),
                ("Aetna",               200...400),
                ("NYU Langone",         50...300)
            ]),
            (.subscriptions, [
                ("Spotify",             11...11),
                ("Netflix",             15...15),
                ("Hulu",                12...18),
                ("Apple One",           20...20),
                ("Dropbox",             10...10),
                ("Peloton",             44...44)
            ]),
            (.personalCare, [
                ("Great Clips",         20...30),
                ("Drybar",              45...65),
                ("Ulta Beauty",         25...80),
                ("Sephora",             30...120)
            ]),
            (.education, [
                ("Coursera",            39...199),
                ("Udemy",               15...50),
                ("LinkedIn Learning",   30...40),
                ("Barnes & Noble",      15...60)
            ])
        ]

        // Weight categories to reflect realistic spending distribution
        let weights: [Double] = [20, 18, 12, 8, 10, 7, 5, 6, 4, 3]
        let selected = weightedRandom(from: pool, weights: weights)
        let (merchant, range) = selected.1.randomElement()!
        let amount = Double.random(in: range)

        return (selected.0, merchant, -amount)
    }

    private static func weightedRandom<T>(from array: [T], weights: [Double]) -> T {
        let total = weights.reduce(0, +)
        var roll = Double.random(in: 0..<total)
        for (item, weight) in zip(array, weights) {
            roll -= weight
            if roll <= 0 { return item }
        }
        return array.last!
    }

    // MARK: - Budget Categories

    private static func createBudgetCategories(context: ModelContext) {
        let defaults: [(String, String, Double, TransactionCategory)] = [
            ("Groceries",       "🛒", 600,  .groceries),
            ("Dining Out",      "🍽️", 400,  .dining),
            ("Transportation",  "🚗", 250,  .transportation),
            ("Entertainment",   "🎬", 150,  .entertainment),
            ("Shopping",        "🛍️", 300,  .shopping),
            ("Utilities",       "💡", 250,  .utilities),
            ("Healthcare",      "🏥", 200,  .healthcare),
            ("Subscriptions",   "📱", 100,  .subscriptions)
        ]

        for (name, emoji, limit, category) in defaults {
            let budgetCategory = BudgetCategory(
                name: name,
                emoji: emoji,
                monthlyLimit: limit,
                category: category
            )
            context.insert(budgetCategory)
        }
    }

    // MARK: - Net Worth Snapshots

    private static func createNetWorthSnapshots(context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()

        // 12 months of gradual growth: net worth from ~$50K to ~$61K
        let baseAssets:      Double = 50_000
        let baseLiabilities: Double = 8_500
        let monthlyGrowth:   Double = 950

        for monthOffset in (0..<12).reversed() {
            guard let date = calendar.date(
                byAdding: .month, value: -monthOffset, to: today.startOfMonth
            ) else { continue }

            let elapsed = Double(11 - monthOffset)
            let totalAssets      = baseAssets      + elapsed * monthlyGrowth
            let totalLiabilities = baseLiabilities - elapsed * 120  // paying down debt

            let snapshot = NetWorthSnapshot(
                date: date,
                totalAssets: totalAssets,
                totalLiabilities: max(totalLiabilities, 0)
            )
            context.insert(snapshot)
        }
    }
}
