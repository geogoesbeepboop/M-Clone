import SwiftUI

/// Root view of the chat sheet — lists all past chat sessions and lets
/// the user create new ones, switch models, or continue existing conversations.
struct ChatHistoryView: View {

    let viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var sessions: [ChatSession] = []
    @State private var navigateToChat = false
    @State private var showSettings = false

    var body: some View {
        Group {
            if sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") { dismiss() }
                    .tint(CrownTheme.primaryBlue)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(CrownTheme.primaryBlue)
                    }

                    Button {
                        viewModel.createNewSession()
                        navigateToChat = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(CrownTheme.primaryBlue)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToChat) {
            ChatView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSettings) {
            ChatModelSettingsView(viewModel: viewModel)
        }
        .onAppear {
            sessions = viewModel.fetchSessions()
        }
    }

    // MARK: - Session List

    private var sessionList: some View {
        List {
            ForEach(sessions) { session in
                Button {
                    viewModel.openSession(session)
                    navigateToChat = true
                } label: {
                    sessionRow(session)
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteSession(sessions[index])
                }
                sessions = viewModel.fetchSessions()
            }
        }
        .listStyle(.insetGrouped)
    }

    private func sessionRow(_ session: ChatSession) -> some View {
        HStack(spacing: 12) {
            // Model icon
            Image(systemName: providerIcon(for: session))
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(providerColor(for: session))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(CrownTheme.subheadFont)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(providerName(for: session))
                        .font(CrownTheme.caption2Font)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(session.updatedAt.formatted(.relative(presentation: .named)))
                        .font(CrownTheme.caption2Font)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(CrownTheme.primaryBlue)

            VStack(spacing: 8) {
                Text("No Conversations Yet")
                    .font(CrownTheme.headlineFont)
                Text("Start a new chat with your AI financial assistant.")
                    .font(CrownTheme.subheadFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.createNewSession()
                navigateToChat = true
            } label: {
                Label("Start New Chat", systemImage: "plus.bubble")
                    .font(CrownTheme.headlineFont)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(CrownTheme.primaryBlue)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(CrownTheme.horizontalPadding)
    }

    // MARK: - Helpers

    private func providerIcon(for session: ChatSession) -> String {
        (ChatModelProvider(rawValue: session.modelProvider) ?? .claude).iconName
    }

    private func providerName(for session: ChatSession) -> String {
        (ChatModelProvider(rawValue: session.modelProvider) ?? .claude).displayName
    }

    private func providerColor(for session: ChatSession) -> Color {
        let provider = ChatModelProvider(rawValue: session.modelProvider) ?? .claude
        return provider == .claude ? CrownTheme.primaryBlue : Color(.systemGray)
    }
}
