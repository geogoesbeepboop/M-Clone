import SwiftUI

/// AI financial assistant chat powered by Claude.
///
/// When Claude is not configured (no API key), shows setup instructions instead.
/// Conversation history is persisted in SwiftData across launches.
struct ChatView: View {

    @Environment(\.accountRepository)     private var accountRepo
    @Environment(\.transactionRepository) private var transactionRepo
    @Environment(\.budgetRepository)      private var budgetRepo
    @Environment(\.netWorthRepository)    private var netWorthRepo
    @Environment(\.modelContext)          private var modelContext

    @State private var viewModel: ChatViewModel?

    var body: some View {
        Group {
            if AppConfig.isClaudeConfigured {
                if let vm = viewModel {
                    chatContent(vm: vm)
                } else {
                    ProgressView()
                }
            } else {
                notConfiguredView
            }
        }
        .navigationTitle("Financial Chat")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if viewModel == nil {
                let vm = ChatViewModel(
                    accountRepo:     accountRepo,
                    transactionRepo: transactionRepo,
                    budgetRepo:      budgetRepo,
                    netWorthRepo:    netWorthRepo,
                    modelContext:    modelContext
                )
                viewModel = vm
                vm.loadMessages()
            }
        }
    }

    // MARK: - Chat Content

    @ViewBuilder
    private func chatContent(vm: ChatViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if vm.messages.isEmpty {
                            suggestionsView(vm: vm)
                        } else {
                            ForEach(vm.messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }

                            if vm.isLoading {
                                typingIndicator
                            }
                        }
                    }
                    .padding(.horizontal, CrownTheme.horizontalPadding)
                    .padding(.top, CrownTheme.sectionSpacing)
                    .padding(.bottom, 12)
                }
                .onChange(of: vm.messages.count) {
                    if let last = vm.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: vm.isLoading) {
                    if vm.isLoading, let last = vm.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            ChatInputView(
                text: Binding(get: { vm.inputText }, set: { vm.inputText = $0 }),
                isLoading: vm.isLoading,
                onSend: { Task { await vm.sendMessage() } }
            )
        }
        .background(CrownTheme.screenBackground)
        .toolbar {
            if !vm.messages.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.clearHistory()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(CrownTheme.expense)
                    }
                }
            }
        }
    }

    // MARK: - Suggestions (empty state)

    private func suggestionsView(vm: ChatViewModel) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(CrownTheme.primaryBlue)
                Text("Crown AI Assistant")
                    .font(CrownTheme.headlineFont)
                Text("Ask me anything about your finances.\nI have context on your accounts, budget, and transactions.")
                    .font(CrownTheme.captionFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            VStack(spacing: 10) {
                ForEach(vm.suggestedQuestions, id: \.self) { question in
                    Button {
                        Task { await vm.sendSuggestedQuestion(question) }
                    } label: {
                        HStack {
                            Text(question)
                                .font(CrownTheme.subheadFont)
                                .foregroundStyle(CrownTheme.primaryBlue)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(CrownTheme.primaryBlue.opacity(0.6))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.adaptiveLightBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(CrownTheme.primaryBlue)
                .clipShape(Circle())

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer(minLength: 48)
        }
    }

    // MARK: - Not Configured View

    private var notConfiguredView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "key.slash")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Text("Claude API Not Configured")
                        .font(CrownTheme.headlineFont)
                    Text("Add your Anthropic API key to enable the AI chat assistant.")
                        .font(CrownTheme.bodyFont)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 8) {
                    setupStep(number: "1", text: "Get your key at console.anthropic.com")
                    setupStep(number: "2", text: "In Xcode: Product → Scheme → Edit Scheme")
                    setupStep(number: "3", text: "Run → Arguments → Environment Variables")
                    setupStep(number: "4", text: "Add: CLAUDE_API_KEY = your_key_here")
                }
                .padding()
                .background(CrownTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CrownTheme.cardCornerRadius))
            }
            .padding(CrownTheme.horizontalPadding)
        }
        .background(CrownTheme.screenBackground)
    }

    private func setupStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(CrownTheme.caption2Font)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(CrownTheme.primaryBlue)
                .clipShape(Circle())
            Text(text)
                .font(CrownTheme.captionFont)
        }
    }
}

#Preview {
    NavigationStack { ChatView() }
}
