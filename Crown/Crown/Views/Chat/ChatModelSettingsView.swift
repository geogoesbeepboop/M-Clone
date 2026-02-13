import SwiftUI

/// Settings sheet for the chat — model selection and streaming toggle.
struct ChatModelSettingsView: View {

    let viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Model selection
                Section {
                    ForEach(ChatModelProvider.allCases) { provider in
                        Button {
                            viewModel.selectedProvider = provider
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: provider.iconName)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(provider == .claude ? CrownTheme.primaryBlue : Color(.systemGray))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.displayName)
                                        .font(CrownTheme.subheadFont)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text(provider.description)
                                        .font(CrownTheme.caption2Font)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if viewModel.selectedProvider == provider {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(CrownTheme.primaryBlue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("AI Model")
                } footer: {
                    if viewModel.selectedProvider == .claude && !AppConfig.isClaudeConfigured {
                        Text("Claude API key is not configured. Add CLAUDE_API_KEY to your Xcode scheme environment variables.")
                            .foregroundStyle(CrownTheme.budgetRed)
                    } else if viewModel.selectedProvider == .foundationModel && !FoundationModelService.isAvailable {
                        Text("Apple Intelligence is not available on this device. Enable it in Settings > Apple Intelligence & Siri.")
                            .foregroundStyle(CrownTheme.budgetRed)
                    }
                }

                // Claude model variant picker (only shown when Claude is selected)
                if viewModel.selectedProvider == .claude {
                    Section {
                        ForEach(ClaudeModel.allCases) { model in
                            Button {
                                viewModel.selectedClaudeModel = model
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.displayName)
                                            .font(CrownTheme.subheadFont)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        Text(model.description)
                                            .font(CrownTheme.caption2Font)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if viewModel.selectedClaudeModel == model {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(CrownTheme.primaryBlue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Claude Model")
                    } footer: {
                        Text("Model ID: \(viewModel.selectedClaudeModel.rawValue)")
                            .font(CrownTheme.caption2Font)
                    }
                }

                // Streaming toggle
                Section {
                    Toggle(isOn: Binding(
                        get: { viewModel.streamingEnabled },
                        set: { viewModel.streamingEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Streaming Responses")
                                .font(CrownTheme.subheadFont)
                                .fontWeight(.medium)
                            Text("Show responses as they are generated, token by token")
                                .font(CrownTheme.caption2Font)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(CrownTheme.primaryBlue)
                } header: {
                    Text("Response Mode")
                }
            }
            .navigationTitle("Chat Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(CrownTheme.primaryBlue)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
