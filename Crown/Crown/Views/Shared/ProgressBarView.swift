import SwiftUI

/// Horizontal progress bar that turns red when progress exceeds 100%.
struct ProgressBarView: View {
    let progress: Double   // 0.0 to 1.0+; values > 1.0 indicate over-budget
    var height: CGFloat = 8
    var tint: Color = CrownTheme.primaryBlue

    private var effectiveColor: Color {
        progress > 1.0 ? CrownTheme.expense : tint
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(Color(.secondarySystemFill))

                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(effectiveColor.gradient)
                    .frame(width: geo.size.width * clampedProgress)
                    .animation(.easeInOut(duration: 0.4), value: clampedProgress)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 12) {
        ProgressBarView(progress: 0.4)
        ProgressBarView(progress: 0.85)
        ProgressBarView(progress: 1.1)  // over-budget → red
    }
    .padding()
}
