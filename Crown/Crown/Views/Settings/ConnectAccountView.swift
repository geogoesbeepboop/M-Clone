import SwiftUI

/// Presents the Plaid Link flow and reports back success or exit events.
///
/// Requires the `LinkKit` SPM package to show the actual bank connection UI.
/// Without it, displays setup instructions instead.
///
/// ## Adding Plaid LinkKit
/// In Xcode: File → Add Package Dependencies →
/// `https://github.com/plaid/plaid-link-ios-spm` → product: `LinkKit`
struct ConnectAccountView: View {

    let linkToken: String
    let onSuccess: (String, [String: Any]) -> Void
    let onExit: () -> Void

    var body: some View {
        #if canImport(LinkKit)
        PlaidLinkBridgeView(
            linkToken: linkToken,
            onSuccess: onSuccess,
            onExit: onExit
        )
        #else
        setupInstructions
        #endif
    }

    private var setupInstructions: some View {
        VStack(spacing: 24) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(CrownTheme.primaryBlue)

            VStack(spacing: 8) {
                Text("Plaid SDK Not Installed")
                    .font(CrownTheme.headlineFont)
                Text("To enable real bank connections, add the Plaid LinkKit package in Xcode:")
                    .font(CrownTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                instructionRow(number: "1", text: "File → Add Package Dependencies")
                instructionRow(number: "2", text: "Enter: github.com/plaid/plaid-link-ios-spm")
                instructionRow(number: "3", text: "Select product: LinkKit")
                instructionRow(number: "4", text: "Add PLAID_CLIENT_ID and PLAID_SECRET\nto your Xcode scheme environment variables")
            }
            .padding()
            .background(CrownTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CrownTheme.cardCornerRadius))

            Button("Dismiss") { onExit() }
                .buttonStyle(.crownSecondary)
        }
        .padding(CrownTheme.cardPadding * 1.5)
    }

    private func instructionRow(number: String, text: String) -> some View {
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

// MARK: - Plaid UIViewControllerRepresentable bridge (only compiled when LinkKit is present)

#if canImport(LinkKit)
import LinkKit

private struct PlaidLinkBridgeView: UIViewControllerRepresentable {

    let linkToken: String
    let onSuccess: (String, [String: Any]) -> Void
    let onExit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSuccess: onSuccess, onExit: onExit)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        print("[Crown/Plaid] makeUIViewController() — token prefix: \(linkToken.prefix(20))…")
        var config = LinkTokenConfiguration(token: linkToken) { result in
            // Parse the raw JSON metadata string into [String: Any]
            var metadataDict: [String: Any] = [:]
            if let jsonString = result.metadata.metadataJSON,
               let data = jsonString.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                metadataDict = parsed
            }
            print("[Crown/Plaid] Plaid Link onSuccess — publicToken prefix: \(result.publicToken.prefix(12))…")
            context.coordinator.onSuccess(result.publicToken, metadataDict)
        }
        config.onExit = { (exit: LinkExit) in
            print("[Crown/Plaid] Plaid Link onExit — error: \(exit.error?.localizedDescription ?? "none")")
            context.coordinator.onExit()
        }
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        // Present Plaid Link on appear.
        // IMPORTANT: handler must be retained on the Coordinator for the entire Link session.
        // If handler is released, the Link webview loses its delegate and freezes on the loading screen.
        switch Plaid.create(config) {
        case .success(let handler):
            print("[Crown/Plaid] Plaid.create() → success, retaining handler and calling open()")
            context.coordinator.handler = handler  // Retain strongly — prevents freeze on loading screen
            DispatchQueue.main.async {
                handler.open(presentUsing: .viewController(vc))
            }
        case .failure(let error):
            // If handler creation fails, fall back to dismissing
            print("[Crown/Plaid] Plaid.create() → FAILED: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.onExit()
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator {
        let onSuccess: (String, [String: Any]) -> Void
        let onExit: () -> Void
        /// Retains the Plaid Link handler for the entire session.
        /// Without this, the handler is released after handler.open() returns,
        /// causing the Plaid Link webview to freeze on the loading screen.
        var handler: Handler?

        init(onSuccess: @escaping (String, [String: Any]) -> Void, onExit: @escaping () -> Void) {
            self.onSuccess = onSuccess
            self.onExit    = onExit
        }
    }
}
#endif
