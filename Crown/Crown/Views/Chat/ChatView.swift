import SwiftUI

/// AI financial assistant chat — shows messages for the active session.
///
/// Navigated to from `ChatHistoryView` with a session already loaded
/// on the shared `ChatViewModel`.
struct ChatView: View {

    let viewModel: ChatViewModel

    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.messages.isEmpty {
                            suggestionsView
                        } else {
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isLoading && !viewModel.streamingEnabled {
                                typingIndicator
                            }
                        }
                    }
                    .padding(.horizontal, CrownTheme.horizontalPadding)
                    .padding(.top, CrownTheme.sectionSpacing)
                    .padding(.bottom, 12)
                }
                .onChange(of: viewModel.messages.count) {
                    if let last = viewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isLoading) {
                    if viewModel.isLoading, let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.streamingContent) {
                    // Auto-scroll as streaming content grows
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            ChatInputView(
                text: Binding(
                    get: { viewModel.inputText },
                    set: { viewModel.inputText = $0 }
                ),
                isLoading: viewModel.isLoading,
                onSend: { Task { await viewModel.sendMessage() } }
            )
        }
        .background(CrownTheme.screenBackground)
        .navigationTitle(viewModel.currentSession?.title ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    // Model indicator chip
                    Button {
                        showSettings = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.selectedProvider.iconName)
                                .font(.caption2)
                            Text(viewModel.modelDisplayName)
                                .font(CrownTheme.caption2Font)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CrownTheme.primaryBlue)
                        .clipShape(Capsule())
                    }

                    if !viewModel.messages.isEmpty {
                        Button {
                            viewModel.clearHistory()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(CrownTheme.expense)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ChatModelSettingsView(viewModel: viewModel)
        }
    }

    // MARK: - Suggestions (empty state)

    private var suggestionsView: some View {
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
                ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                    Button {
                        Task { await viewModel.sendSuggestedQuestion(question) }
                    } label: {
                        HStack {
                            Text(question)
                                .font(CrownTheme.subheadFont)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
}
