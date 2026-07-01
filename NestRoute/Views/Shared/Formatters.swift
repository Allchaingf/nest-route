//
//  Formatters.swift
//  NestRoute
//
//  Cached date / time formatters used throughout the UI.
//

import Foundation

enum NRFormat {
    static let dayMonth: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f
    }()
    static let dayMonthYear: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMM yyyy"; return f
    }()
    static let weekdayDayMonth: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE, d MMM"; return f
    }()
    static let time: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
    static let monthYear: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()
    static let fileStamp: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMM yyyy, HH:mm"; return f
    }()

    static func date(_ d: Date) -> String { dayMonth.string(from: d) }
    static func dateTime(_ d: Date) -> String {
        "\(weekdayDayMonth.string(from: d)) · \(time.string(from: d))"
    }
    static func relativeDay(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInTomorrow(d) { return "Tomorrow" }
        if cal.isDateInYesterday(d) { return "Yesterday" }
        return weekdayDayMonth.string(from: d)
    }
}
