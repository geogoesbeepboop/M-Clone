import Foundation

// MARK: - Protocol

/// Sends messages to the Claude Messages API and returns the assistant's reply.
///
/// - Important: For production, route requests through your own backend proxy
///   so the API key is never bundled in the iOS binary.
protocol ClaudeServiceProtocol {
    func sendMessage(messages: [ClaudeMessage], systemPrompt: String?) async throws -> String
}

// MARK: - Message Types

/// A single turn in a Claude conversation.
struct ClaudeMessage: Codable {
    let role: String    // "user" or "assistant"
    let content: String
}

// MARK: - Request / Response Codable types

private struct ClaudeRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String?
    let messages: [ClaudeMessage]
}

private struct ClaudeResponse: Decodable {
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }

    var firstText: String? {
        content.first(where: { $0.type == "text" })?.text
    }
}

// MARK: - Error Types

enum ClaudeError: LocalizedError {
    case notConfigured
    case invalidResponse
    case apiError(Int, String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Claude API key is not configured. Add CLAUDE_API_KEY to your Xcode scheme environment variables."
        case .invalidResponse:
            return "Received an invalid response from Claude."
        case .apiError(let code, let message):
            return "Claude API error \(code): \(message)"
        case .decodingError(let error):
            return "Failed to parse Claude response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Implementation

/// URLSession-based client for the Anthropic Messages API.
///
/// - TODO: PRODUCTION — route through a backend proxy; never expose the key in the client.
final class ClaudeService: ClaudeServiceProtocol {

    private let session: URLSession
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func sendMessage(messages: [ClaudeMessage], systemPrompt: String? = nil) async throws -> String {
        guard AppConfig.isClaudeConfigured else { throw ClaudeError.notConfigured }

        let body = ClaudeRequest(
            model:      AppConfig.claudeModel,
            max_tokens: 1024,
            system:     systemPrompt,
            messages:   messages
        )

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json",      forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.claudeAPIKey,  forHTTPHeaderField: "x-api-key")
        request.setValue(AppConfig.claudeAPIVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw ClaudeError.invalidResponse }

        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ClaudeAPIError.self, from: data))?.error.message
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown error"
            throw ClaudeError.apiError(http.statusCode, message)
        }

        do {
            let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            guard let text = decoded.firstText else { throw ClaudeError.invalidResponse }
            return text
        } catch let error as ClaudeError {
            throw error
        } catch {
            throw ClaudeError.decodingError(error)
        }
    }
}

// MARK: - API Error Shape

private struct ClaudeAPIError: Decodable {
    struct ErrorDetail: Decodable {
        let type: String
        let message: String
    }
    let error: ErrorDetail
}
