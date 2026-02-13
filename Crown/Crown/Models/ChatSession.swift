import Foundation
import SwiftData

/// A single chat conversation that groups related messages together.
///
/// Sessions are persisted on-device via SwiftData so users can revisit
/// and continue past conversations.
@Model
final class ChatSession {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var modelProvider: String   // "claude" or "foundationModel"

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage]

    init(title: String = "New Chat", modelProvider: String = "claude") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.modelProvider = modelProvider
        self.messages = []
    }

    /// Auto-generates a title from the first user message.
    func updateTitleFromFirstMessage() {
        guard title == "New Chat",
              let firstUserMsg = messages
                .sorted(by: { $0.timestamp < $1.timestamp })
                .first(where: { $0.role == .user })
        else { return }

        let text = firstUserMsg.content
        title = String(text.prefix(40)) + (text.count > 40 ? "..." : "")
    }
}
