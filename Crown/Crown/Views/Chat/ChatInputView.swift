import SwiftUI
import UIKit

/// Sticky input bar at the bottom of the chat — text field + send button.
struct ChatInputView: View {

    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            TextField("Ask about your finances...", text: $text, axis: .vertical)
                .font(CrownTheme.bodyFont)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit {
                    guard !isLoading else { return }
                    onSend()
                }

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onSend()
            }) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 40, height: 40)
                .background(
                    (text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        ? Color.secondary.opacity(0.4)
                        : CrownTheme.primaryBlue
                )
                .clipShape(Circle())
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .animation(.easeInOut(duration: 0.15), value: isLoading)
        }
        .padding(.horizontal, CrownTheme.horizontalPadding)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
