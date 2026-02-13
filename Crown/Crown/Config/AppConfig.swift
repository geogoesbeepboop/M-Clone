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
    static let claudeModel:  String = "claude-sonnet-4-20250514"
    static let claudeAPIVersion = "2023-06-01"

    // MARK: - Feature Flags
    static var isPlaidConfigured: Bool { !plaidClientId.isEmpty && !plaidSecret.isEmpty }
    static var isClaudeConfigured: Bool { !claudeAPIKey.isEmpty }

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
