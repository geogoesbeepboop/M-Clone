import Foundation
import SwiftData
import Observation

/// Manages a single chat session — persists messages, builds context,
/// and dispatches to the selected AI model provider with optional streaming.
@Observable
final class ChatViewModel {

    // MARK: - State

    var messages:       [ChatMessage] = []
    var inputText:      String        = ""
    var isLoading:      Bool          = false
    var errorMessage:   String?       = nil
    var currentSession: ChatSession?

    /// Tracks the content being streamed so the view can observe changes.
    var streamingContent: String = ""

    /// Which model provider the active session uses.
    var selectedProvider: ChatModelProvider {
        didSet {
            AppConfig.chatModelProvider = selectedProvider
        }
    }

    /// Which specific Claude model variant to use.
    var selectedClaudeModel: ClaudeModel {
        didSet {
            AppConfig.selectedClaudeModel = selectedClaudeModel
        }
    }

    /// Whether streaming is enabled.
    var streamingEnabled: Bool {
        didSet {
            AppConfig.streamingEnabled = streamingEnabled
        }
    }

    /// Returns a user-facing label for the currently active model (e.g. "Sonnet 4.5").
    var modelDisplayName: String {
        switch selectedProvider {
        case .claude:          return selectedClaudeModel.displayName
        case .foundationModel: return "Apple Intelligence"
        }
    }

    // MARK: - Private

    private let claudeService:          ChatServiceProtocol
    private let foundationModelService: ChatServiceProtocol
    private let contextBuilder:         FinancialContextBuilder
    private let modelContext:           ModelContext

    /// Returns the service for the currently selected provider.
    private var activeService: ChatServiceProtocol {
        switch selectedProvider {
        case .claude:          return claudeService
        case .foundationModel: return foundationModelService
        }
    }

    // MARK: - Suggested Questions

    let suggestedQuestions: [String] = [
        "How am I doing on my budget?",
        "What are my biggest spending categories this month?",
        "How can I reduce my expenses?",
        "What's my net worth trend?",
        "Am I saving enough each month?"
    ]

    // MARK: - Init

    init(
        accountRepo:     AccountRepositoryProtocol,
        transactionRepo: TransactionRepositoryProtocol,
        budgetRepo:      BudgetRepositoryProtocol,
        netWorthRepo:    NetWorthRepositoryProtocol,
        modelContext:    ModelContext,
        claudeService:   ChatServiceProtocol = ClaudeService(),
        foundationModelService: ChatServiceProtocol = FoundationModelService()
    ) {
        self.claudeService          = claudeService
        self.foundationModelService = foundationModelService
        self.modelContext           = modelContext
        self.selectedProvider       = AppConfig.chatModelProvider
        self.selectedClaudeModel    = AppConfig.selectedClaudeModel
        self.streamingEnabled       = AppConfig.streamingEnabled
        self.contextBuilder = FinancialContextBuilder(
            accountRepo:     accountRepo,
            transactionRepo: transactionRepo,
            budgetRepo:      budgetRepo,
            netWorthRepo:    netWorthRepo
        )
    }

    // MARK: - Session Management

    /// Loads all chat sessions sorted by most recently updated.
    func fetchSessions() -> [ChatSession] {
        let descriptor = FetchDescriptor<ChatSession>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Opens an existing session — loads its messages.
    func openSession(_ session: ChatSession) {
        currentSession = session
        selectedProvider = ChatModelProvider(rawValue: session.modelProvider) ?? .claude
        loadMessages(for: session)
    }

    /// Creates a new session and makes it the active session.
    func createNewSession() {
        let session = ChatSession(
            title: "New Chat",
            modelProvider: selectedProvider.rawValue
        )
        modelContext.insert(session)
        try? modelContext.save()
        currentSession = session
        messages = []
    }

    /// Deletes a chat session and all its messages.
    func deleteSession(_ session: ChatSession) {
        modelContext.delete(session)
        try? modelContext.save()
        if currentSession?.id == session.id {
            currentSession = nil
            messages = []
        }
    }

    // MARK: - Load Messages

    func loadMessages(for session: ChatSession) {
        let sessionID = session.id
        var descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate<ChatMessage> { $0.session?.id == sessionID },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        descriptor.fetchLimit = 200
        messages = (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Loads messages for the current session (convenience).
    func loadMessages() {
        guard let session = currentSession else {
            messages = []
            return
        }
        loadMessages(for: session)
    }

    // MARK: - Send

    /// Appends the user's message, calls the active AI service, and appends the reply.
    /// Uses streaming or non-streaming based on the `streamingEnabled` flag.
    @MainActor
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        // Ensure we have an active session
        if currentSession == nil {
            createNewSession()
        }
        guard let session = currentSession else { return }

        inputText    = ""
        errorMessage = nil

        // Persist and show the user message immediately
        let userMessage = ChatMessage(content: text, role: .user)
        userMessage.session = session
        modelContext.insert(userMessage)
        messages.append(userMessage)

        // Auto-title from first user message
        session.updateTitleFromFirstMessage()
        session.updatedAt = Date()
        session.modelProvider = selectedProvider.rawValue

        isLoading = true

        let systemPrompt = contextBuilder.buildSystemPrompt()
        let history      = buildHistory()

        if streamingEnabled {
            await sendStreaming(session: session, history: history, systemPrompt: systemPrompt)
        } else {
            await sendNonStreaming(session: session, history: history, systemPrompt: systemPrompt)
        }

        isLoading = false
    }

    // MARK: - Non-streaming Send

    @MainActor
    private func sendNonStreaming(session: ChatSession, history: [ClaudeMessage], systemPrompt: String) async {
        do {
            let reply = try await activeService.sendMessage(
                messages:     history,
                systemPrompt: systemPrompt
            )

            let assistantMessage = ChatMessage(content: reply, role: .assistant)
            assistantMessage.session = session
            modelContext.insert(assistantMessage)
            messages.append(assistantMessage)

            session.updatedAt = Date()
            try? modelContext.save()
        } catch {
            appendError(error, session: session)
        }
    }

    // MARK: - Streaming Send

    @MainActor
    private func sendStreaming(session: ChatSession, history: [ClaudeMessage], systemPrompt: String) async {
        // Create the assistant message placeholder
        let assistantMessage = ChatMessage(content: "", role: .assistant)
        assistantMessage.session = session
        modelContext.insert(assistantMessage)
        messages.append(assistantMessage)
        streamingContent = ""

        let stream = activeService.streamMessage(
            messages:     history,
            systemPrompt: systemPrompt
        )

        do {
            for try await delta in stream {
                streamingContent += delta
                assistantMessage.content = streamingContent
            }

            session.updatedAt = Date()
            try? modelContext.save()
        } catch {
            // If streaming failed and we have no content, replace with error
            if assistantMessage.content.isEmpty {
                assistantMessage.content = "Sorry, I couldn't respond right now. \(error.localizedDescription)"
            }
            try? modelContext.save()
        }

        streamingContent = ""
    }

    // MARK: - Helpers

    /// Convenience for sending a suggested question.
    @MainActor
    func sendSuggestedQuestion(_ question: String) async {
        inputText = question
        await sendMessage()
    }

    /// Deletes all messages in the current session.
    func clearHistory() {
        messages.forEach { modelContext.delete($0) }
        messages = []
        if let session = currentSession {
            session.updatedAt = Date()
        }
        try? modelContext.save()
    }

    // MARK: - Private Helpers

    /// Converts persisted ChatMessages into the ClaudeMessage format for the API request.
    private func buildHistory() -> [ClaudeMessage] {
        let recent = messages.suffix(20)
        return recent.map { ClaudeMessage(role: $0.role.rawValue, content: $0.content) }
    }

    private func appendError(_ error: Error, session: ChatSession) {
        let errMsg = ChatMessage(
            content: "Sorry, I couldn't respond right now. \(error.localizedDescription)",
            role:    .assistant
        )
        errMsg.session = session
        modelContext.insert(errMsg)
        messages.append(errMsg)
        try? modelContext.save()
    }
}
