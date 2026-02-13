import Foundation

extension Date {

    // MARK: - Month boundaries

    var startOfMonth: Date {
        Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: self)
        ) ?? self
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    // MARK: - Comparison helpers

    func isInSameMonth(as other: Date) -> Bool {
        let cal = Calendar.current
        return cal.component(.month, from: self) == cal.component(.month, from: other) &&
               cal.component(.year,  from: self) == cal.component(.year,  from: other)
    }

    func isInSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    // MARK: - Formatted strings

    var monthYearString: String {
        formatted(.dateTime.month(.wide).year())
    }

    var shortMonthYearString: String {
        formatted(.dateTime.month(.abbreviated).year())
    }

    var relativeMonthLabel: String {
        let cal = Calendar.current
        if isInSameMonth(as: Date()) { return "This Month" }
        if let last = cal.date(byAdding: .month, value: -1, to: Date()),
           isInSameMonth(as: last) { return "Last Month" }
        return shortMonthYearString
    }

    // MARK: - Navigation helpers

    func monthOffset(by offset: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: offset, to: self) ?? self
    }

    var month: Int { Calendar.current.component(.month, from: self) }
    var year:  Int { Calendar.current.component(.year,  from: self) }
}
