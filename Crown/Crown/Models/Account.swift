import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID
    var name: String
    var institution: String
    var type: AccountType
    var balance: Double
    var plaidAccountId: String?
    var plaidAccessToken: String?
    var lastSynced: Date?
    var isHidden: Bool

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]

    init(
        name: String,
        institution: String,
        type: AccountType,
        balance: Double,
        plaidAccountId: String? = nil,
        plaidAccessToken: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.institution = institution
        self.type = type
        self.balance = balance
        self.plaidAccountId = plaidAccountId
        self.plaidAccessToken = plaidAccessToken
        self.lastSynced = nil
        self.isHidden = false
        self.transactions = []
    }

    /// Display balance — positive for assets, shows raw (negative) for liabilities
    var displayBalance: Double {
        balance
    }

    /// Absolute balance for summation purposes
    var absoluteBalance: Double {
        abs(balance)
    }
}
