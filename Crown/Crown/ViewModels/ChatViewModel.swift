import Foundation
import SwiftData
import Observation

/// Manages the AI chat conversation — persists messages, builds context, and calls Claude.
@Observable
final class ChatViewModel {

    // MARK: - State

    var messages:       [ChatMessage] = []
    var inputText:      String        = ""
    var isLoading:      Bool          = false
    var errorMessage:   String?       = nil

    // MARK: - Private

    private let claudeService:   ClaudeServiceProtocol
    private let contextBuilder:  FinancialContextBuilder
    private let modelContext:    ModelContext

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
        claudeService:   ClaudeServiceProtocol = ClaudeService()
    ) {
        self.claudeService  = claudeService
        self.modelContext   = modelContext
        self.contextBuilder = FinancialContextBuilder(
            accountRepo:     accountRepo,
            transactionRepo: transactionRepo,
            budgetRepo:      budgetRepo,
            netWorthRepo:    netWorthRepo
        )
    }

    // MARK: - Load

    func loadMessages() {
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        messages = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Send

    /// Appends the user's message, calls Claude, and appends the assistant reply.
    @MainActor
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        inputText   = ""
        errorMessage = nil

        // Persist and show the user message immediately
        let userMessage = ChatMessage(content: text, role: .user)
        modelContext.insert(userMessage)
        messages.append(userMessage)

        isLoading = true

        do {
            let systemPrompt = contextBuilder.buildSystemPrompt()
            let history      = buildHistory()
            let reply        = try await claudeService.sendMessage(
                messages:     history,
                systemPrompt: systemPrompt
            )

            let assistantMessage = ChatMessage(content: reply, role: .assistant)
            modelContext.insert(assistantMessage)
            messages.append(assistantMessage)
            try? modelContext.save()
        } catch {
            // Show error as an assistant message so it appears inline in the chat
            let errMsg = ChatMessage(
                content: "Sorry, I couldn't respond right now. \(error.localizedDescription)",
                role:    .assistant
            )
            modelContext.insert(errMsg)
            messages.append(errMsg)
            try? modelContext.save()
        }

        isLoading = false
    }

    /// Convenience for sending a suggested question by setting input and immediately dispatching.
    @MainActor
    func sendSuggestedQuestion(_ question: String) async {
        inputText = question
        await sendMessage()
    }

    /// Deletes all chat history.
    func clearHistory() {
        messages.forEach { modelContext.delete($0) }
        messages = []
        try? modelContext.save()
    }

    // MARK: - Private Helpers

    /// Converts persisted ChatMessages into the ClaudeMessage format for the API request.
    private func buildHistory() -> [ClaudeMessage] {
        // Claude requires alternating user/assistant turns starting with user.
        // Take up to the last 20 messages to stay within context limits.
        let recent = messages.suffix(20)
        return recent.map { ClaudeMessage(role: $0.role.rawValue, content: $0.content) }
    }
}
