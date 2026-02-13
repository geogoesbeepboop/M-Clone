import Foundation

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case checking = "Checking"
    case savings = "Savings"
    case creditCard = "Credit Card"
    case investment = "Investment"
    case loan = "Loan"
    case mortgage = "Mortgage"
    case other = "Other"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .checking: "banknote"
        case .savings: "building.columns"
        case .creditCard: "creditcard"
        case .investment: "chart.line.uptrend.xyaxis"
        case .loan: "doc.text"
        case .mortgage: "house"
        case .other: "ellipsis.circle"
        }
    }

    var isAsset: Bool {
        switch self {
        case .checking, .savings, .investment: true
        case .creditCard, .loan, .mortgage: false
        case .other: true
        }
    }

    var displayName: String { rawValue }
}
