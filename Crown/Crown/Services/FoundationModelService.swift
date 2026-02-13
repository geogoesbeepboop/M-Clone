import Foundation
import FoundationModels

/// On-device language model service using Apple's Foundation Models framework.
///
/// Conforms to `ChatServiceProtocol` so it can be swapped in wherever
/// the Claude service is used. Conversation history is included in the
/// session instructions so the on-device model has full context.
final class FoundationModelService: ChatServiceProtocol {

    /// Checks whether the on-device Foundation Model is available.
    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    // MARK: - Non-streaming

    func sendMessage(messages: [ClaudeMessage], systemPrompt: String?) async throws -> String {
        guard Self.isAvailable else {
            throw FoundationModelError.modelNotAvailable
        }

        let session = try buildSession(messages: messages, systemPrompt: systemPrompt)

        guard let lastMessage = messages.last else {
            throw FoundationModelError.noMessages
        }

        let response = try await session.respond(to: lastMessage.content)
        return normalizeText(response.content)
    }

    // MARK: - Streaming

    func streamMessage(messages: [ClaudeMessage], systemPrompt: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard Self.isAvailable else {
                        throw FoundationModelError.modelNotAvailable
                    }

                    let session = try self.buildSession(messages: messages, systemPrompt: systemPrompt)

                    guard let lastMessage = messages.last else {
                        throw FoundationModelError.noMessages
                    }

                    var lastContent = ""
                    let stream = session.streamResponse(to: lastMessage.content)
                    for try await partial in stream {
                        let current = self.normalizeText(partial.content)
                        // Yield only the new delta since last emission
                        if current.count > lastContent.count {
                            let delta = String(current.dropFirst(lastContent.count))
                            continuation.yield(delta)
                            lastContent = current
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func buildSession(messages: [ClaudeMessage], systemPrompt: String?) throws -> LanguageModelSession {
        var instructions = systemPrompt ?? "You are a helpful personal finance assistant."

        // Include prior conversation turns so the model has context
        if messages.count > 1 {
            instructions += "\n\nPrevious conversation:\n"
            for msg in messages.dropLast() {
                let role = msg.role == "user" ? "User" : "Assistant"
                instructions += "\(role): \(msg.content)\n"
            }
        }

        return LanguageModelSession(instructions: instructions)
    }

    /// Cleans up model output — replaces literal escaped characters with real ones.
    private func normalizeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\t", with: "\t")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum FoundationModelError: LocalizedError {
    case modelNotAvailable
    case noMessages

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "On-device AI model is not available on this device. Ensure Apple Intelligence is enabled in Settings."
        case .noMessages:
            return "No messages to send."
        }
    }
}
