import SwiftUI

/// A single chat bubble — user messages right-aligned blue, assistant left-aligned gray.
struct ChatBubbleView: View {

    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 48) }

            if !isUser {
                // Crown logo avatar
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(CrownTheme.primaryBlue)
                    .clipShape(Circle())
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(CrownTheme.bodyFont)
                    .foregroundStyle(isUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                            ? CrownTheme.primaryBlue
                            : Color(.secondarySystemBackground)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )

                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(CrownTheme.caption2Font)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            if isUser {
                // User avatar placeholder
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if !isUser { Spacer(minLength: 48) }
        }
    }
}
