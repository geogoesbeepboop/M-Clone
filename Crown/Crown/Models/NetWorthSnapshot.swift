import Foundation
import SwiftData

@Model
final class NetWorthSnapshot {
    var id: UUID
    var date: Date
    var totalAssets: Double
    var totalLiabilities: Double

    var netWorth: Double { totalAssets - totalLiabilities }

    init(date: Date, totalAssets: Double, totalLiabilities: Double) {
        self.id = UUID()
        self.date = date
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
    }
}
