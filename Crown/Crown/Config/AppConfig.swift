import Foundation

/// App-wide configuration read from Xcode scheme environment variables.
///
/// To configure, open Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables:
///   - PLAID_CLIENT_ID   : your Plaid client_id
///   - PLAID_SECRET      : your Plaid sandbox secret
///   - CLAUDE_API_KEY    : your Anthropic API key
enum AppConfig {

    // MARK: - Plaid
    // TODO: PRODUCTION — token exchange must be performed server-side.
    // The iOS client should call your own backend, which holds these secrets.
    static let plaidClientId: String = ProcessInfo.processInfo.environment["PLAID_CLIENT_ID"] ?? ""
    static let plaidSecret:   String = ProcessInfo.processInfo.environment["PLAID_SECRET"]    ?? ""
    static let plaidBaseURL:  String = "https://sandbox.plaid.com"   // sandbox only
    // TODO: PRODUCTION — Replace with your own Universal Link (e.g. https://yourdomain.com/plaid/)
    static let plaidRedirectUri: String = "https://cdn.plaid.com/link/v2/stable/sandbox-oauth-a2a-redirect.html"

    // MARK: - Claude
    // TODO: PRODUCTION — route Claude requests through a backend proxy.
    static let claudeAPIKey: String = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
    static let claudeAPIVersion = "2023-06-01"

    // MARK: - Claude Model Selection (persisted in UserDefaults)

    private static let claudeModelKey = "crownClaudeModel"

    /// The selected Claude model variant. Defaults to `.sonnet`.
    static var selectedClaudeModel: ClaudeModel {
        get {
            guard let raw = UserDefaults.standard.string(forKey: claudeModelKey),
                  let model = ClaudeModel(rawValue: raw)
            else { return .sonnet }
            return model
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: claudeModelKey)
        }
    }

    /// The model ID string sent to the Anthropic API.
    static var claudeModel: String { selectedClaudeModel.rawValue }

    // MARK: - Feature Flags
    static var isPlaidConfigured: Bool { !plaidClientId.isEmpty && !plaidSecret.isEmpty }
    static var isClaudeConfigured: Bool { !claudeAPIKey.isEmpty }

    // MARK: - Chat Model Provider (persisted in UserDefaults)

    private static let chatModelKey = "crownChatModelProvider"

    /// The selected chat model provider. Defaults to `.claude`.
    static var chatModelProvider: ChatModelProvider {
        get {
            guard let raw = UserDefaults.standard.string(forKey: chatModelKey),
                  let provider = ChatModelProvider(rawValue: raw)
            else { return .claude }
            return provider
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: chatModelKey)
        }
    }

    // MARK: - Streaming Toggle (persisted in UserDefaults)

    private static let streamingKey = "crownStreamingEnabled"

    /// Whether AI responses stream token-by-token. Defaults to `true`.
    static var streamingEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: streamingKey) != nil else {
                return true  // default: streaming on
            }
            return UserDefaults.standard.bool(forKey: streamingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: streamingKey)
        }
    }

    // MARK: - Appearance (persisted in UserDefaults)

    private static let appearanceKey = "crownAppearanceMode"

    /// User-selected appearance override. Defaults to `.system`.
    static var appearanceMode: String {
        get { UserDefaults.standard.string(forKey: appearanceKey) ?? "system" }
        set { UserDefaults.standard.set(newValue, forKey: appearanceKey) }
    }

    // MARK: - Mock Data Toggle (persisted in UserDefaults)

    private static let mockDataKey = "crownUseMockData"

    /// Whether the app seeds and displays demo data.
    ///
    /// Defaults to `true` on first launch so every screen is populated immediately.
    /// Toggle off in Settings once real bank accounts are connected.
    static var useMockData: Bool {
        get {
            guard UserDefaults.standard.object(forKey: mockDataKey) != nil else {
                return true  // first-launch default: always show demo data
            }
            return UserDefaults.standard.bool(forKey: mockDataKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: mockDataKey)
        }
    }
}

// MARK: - Chat Model Provider Enum

/// Available AI model providers for the chat feature.
enum ChatModelProvider: String, CaseIterable, Identifiable {
    case claude = "claude"
    case foundationModel = "foundationModel"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude:          return "Claude"
        case .foundationModel: return "Apple Intelligence"
        }
    }

    var iconName: String {
        switch self {
        case .claude:          return "sparkles"
        case .foundationModel: return "apple.logo"
        }
    }

    var description: String {
        switch self {
        case .claude:          return "Anthropic's Claude API (requires API key)"
        case .foundationModel: return "On-device Apple Foundation Model"
        }
    }
}

// MARK: - Claude Model Variants

/// Available Claude model variants — Sonnet (balanced), Opus (most capable), Haiku (fastest).
enum ClaudeModel: String, CaseIterable, Identifiable {
    case sonnet = "claude-sonnet-4-5-20250929"
    case opus   = "claude-opus-4-6"
    case haiku  = "claude-haiku-4-5-20251001"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sonnet: return "Sonnet 4.5"
        case .opus:   return "Opus 4.6"
        case .haiku:  return "Haiku 4.5"
        }
    }

    var shortName: String {
        switch self {
        case .sonnet: return "Sonnet"
        case .opus:   return "Opus"
        case .haiku:  return "Haiku"
        }
    }

    var description: String {
        switch self {
        case .sonnet: return "Balanced speed and intelligence"
        case .opus:   return "Most capable, best for complex analysis"
        case .haiku:  return "Fastest responses, great for quick questions"
        }
    }
}
