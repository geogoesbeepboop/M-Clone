import Foundation

enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    case groceries = "Groceries"
    case dining = "Dining"
    case transportation = "Transportation"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case utilities = "Utilities"
    case housing = "Housing"
    case healthcare = "Healthcare"
    case personalCare = "Personal Care"
    case education = "Education"
    case travel = "Travel"
    case subscriptions = "Subscriptions"
    case income = "Income"
    case transfer = "Transfer"
    case fees = "Fees"
    case other = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .groceries: "🛒"
        case .dining: "🍽️"
        case .transportation: "🚗"
        case .entertainment: "🎬"
        case .shopping: "🛍️"
        case .utilities: "💡"
        case .housing: "🏠"
        case .healthcare: "🏥"
        case .personalCare: "💇"
        case .education: "📚"
        case .travel: "✈️"
        case .subscriptions: "📱"
        case .income: "💰"
        case .transfer: "🔄"
        case .fees: "💳"
        case .other: "📦"
        }
    }

    var groupName: String {
        switch self {
        case .groceries, .dining: "Food & Drink"
        case .transportation, .travel: "Getting Around"
        case .entertainment, .subscriptions: "Entertainment"
        case .shopping, .personalCare: "Shopping"
        case .utilities, .housing: "Home"
        case .healthcare: "Health"
        case .education: "Education"
        case .income: "Income"
        case .transfer, .fees, .other: "Other"
        }
    }

    var isExpense: Bool {
        switch self {
        case .income, .transfer: false
        default: true
        }
    }
}
