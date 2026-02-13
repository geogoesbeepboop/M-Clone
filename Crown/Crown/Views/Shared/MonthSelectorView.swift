import SwiftUI

/// Compact month navigator with left/right chevron buttons.
struct MonthSelectorView: View {
    @Binding var selectedMonth: Date

    private var isCurrentMonth: Bool {
        selectedMonth.isInSameMonth(as: Date())
    }

    var body: some View {
        HStack(spacing: 16) {
            Button {
                selectedMonth = selectedMonth.monthOffset(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CrownTheme.primaryBlue)
            }

            Text(selectedMonth.monthYearString)
                .font(CrownTheme.headlineFont)
                .frame(minWidth: 160)
                .animation(.none, value: selectedMonth)

            Button {
                guard !isCurrentMonth else { return }
                selectedMonth = selectedMonth.monthOffset(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isCurrentMonth ? Color.secondary : CrownTheme.primaryBlue)
            }
            .disabled(isCurrentMonth)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    MonthSelectorView(selectedMonth: .constant(Date()))
        .padding()
}
