import SwiftUI

// MARK: - Tab Selection

/// Identifies each tab in the main tab bar for programmatic navigation.
enum CrownTab: String, Hashable {
    case dashboard
    case accounts
    case transactions
    case cashFlow
    case budget
}

private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<CrownTab> = .constant(.dashboard)
}

extension EnvironmentValues {
    var selectedTab: Binding<CrownTab> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

// MARK: - Chat Sheet

/// Environment key that lets any child view trigger the global chat sheet.
private struct ShowChatKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var showChat: Binding<Bool> {
        get { self[ShowChatKey.self] }
        set { self[ShowChatKey.self] = newValue }
    }
}
