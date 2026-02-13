import Foundation

// MARK: - Protocol

/// Unified protocol for AI chat services (Claude API, Apple Foundation Models, etc.).
///
/// Both `sendMessage` (non-streaming) and `streamMessage` (streaming) are required.
/// Streaming yields text deltas that should be appended to the message.
protocol ChatServiceProtocol {
    func sendMessage(messages: [ClaudeMessage], systemPrompt: String?) async throws -> String
    func streamMessage(messages: [ClaudeMessage], systemPrompt: String?) -> AsyncThrowingStream<String, Error>
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
    let stream: Bool
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

// MARK: - SSE Streaming Types

/// Represents a single Server-Sent Event from the Claude streaming API.
private struct StreamEvent: Decodable {
    let type: String
    let delta: Delta?

    struct Delta: Decodable {
        let type: String?
        let text: String?
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
/// Supports both standard and streaming requests.
///
/// - TODO: PRODUCTION — route through a backend proxy; never expose the key in the client.
final class ClaudeService: ChatServiceProtocol {

    private let session: URLSession
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Non-streaming

    func sendMessage(messages: [ClaudeMessage], systemPrompt: String? = nil) async throws -> String {
        guard AppConfig.isClaudeConfigured else { throw ClaudeError.notConfigured }

        let body = ClaudeRequest(
            model:      AppConfig.claudeModel,
            max_tokens: 1024,
            system:     systemPrompt,
            messages:   messages,
            stream:     false
        )

        var request = buildRequest()
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

    // MARK: - Streaming

    func streamMessage(messages: [ClaudeMessage], systemPrompt: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard AppConfig.isClaudeConfigured else { throw ClaudeError.notConfigured }

                    let body = ClaudeRequest(
                        model:      AppConfig.claudeModel,
                        max_tokens: 1024,
                        system:     systemPrompt,
                        messages:   messages,
                        stream:     true
                    )

                    var request = self.buildRequest()
                    request.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await self.session.bytes(for: request)

                    guard let http = response as? HTTPURLResponse else {
                        throw ClaudeError.invalidResponse
                    }

                    guard (200..<300).contains(http.statusCode) else {
                        // Collect error body
                        var errorData = Data()
                        for try await byte in bytes {
                            errorData.append(byte)
                        }
                        let message = (try? JSONDecoder().decode(ClaudeAPIError.self, from: errorData))?.error.message
                            ?? String(data: errorData, encoding: .utf8)
                            ?? "Unknown error"
                        throw ClaudeError.apiError(http.statusCode, message)
                    }

                    // Parse SSE stream line by line
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let json = String(line.dropFirst(6))
                        guard json != "[DONE]" else { break }

                        guard let data = json.data(using: .utf8),
                              let event = try? JSONDecoder().decode(StreamEvent.self, from: data)
                        else { continue }

                        // content_block_delta events carry text chunks
                        if event.type == "content_block_delta",
                           let text = event.delta?.text {
                            continuation.yield(text)
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

    private func buildRequest() -> URLRequest {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json",          forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.claudeAPIKey,      forHTTPHeaderField: "x-api-key")
        request.setValue(AppConfig.claudeAPIVersion,  forHTTPHeaderField: "anthropic-version")
        return request
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
