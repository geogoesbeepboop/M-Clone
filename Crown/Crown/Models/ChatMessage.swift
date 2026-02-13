import Foundation
import SwiftData

enum ChatRole: String, Codable {
    case user
    case assistant
}

@Model
final class ChatMessage {
    var id: UUID
    var timestamp: Date
    var content: String
    var role: ChatRole

    init(content: String, role: ChatRole) {
        self.id = UUID()
        self.timestamp = Date()
        self.content = content
        self.role = role
    }
}
