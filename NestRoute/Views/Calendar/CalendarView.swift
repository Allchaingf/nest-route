//
//  CalendarView.swift
//  NestRoute
//
//  Calendar section (Экран 14 — Events & reminders). Custom month grid with
//  event dots, a selectable day and that day's feed of departures, arrivals,
//  tasks and reminders. New reminders can be added inline.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var settings: AppSettings

    @State private var month = Calendar.current.startOfMonth(for: Date())
    @State private var selected = Calendar.current.startOfDay(for: Date())
    @State private var showAddReminder = false

    private let cal = Calendar.current

    private var weekdaySymbols: [String] {
        settings.weekStartsMonday ? ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
                                  : ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
    }

    var body: some View {
        ZStack {
            NRBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: NRSpacing.md) {
                    NRHeaderBar(title: "Calendar", subtitle: "Events & reminders", showBack: true,
                                trailingIcon: "bell.badge.fill", trailingAction: { showAddReminder = true })

                    monthCard
                    dayFeed
                    TabBarSpacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddReminder) { AddReminderView(defaultDate: selected) }
    }

    // MARK: Month grid

    private var monthCard: some View {
        NRCard {
            VStack(spacing: 14) {
                HStack {
                    Button { changeMonth(-1) } label: {
                        Image(systemName: "chevron.left").foregroundColor(NRColor.accentDeep).padding(8)
                    }.buttonStyle(PlainButtonStyle())
                    Spacer()
                    Text(NRFormat.monthYear.string(from: month))
                        .font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Spacer()
                    Button { changeMonth(1) } label: {
                        Image(systemName: "chevron.right").foregroundColor(NRColor.accentDeep).padding(8)
                    }.buttonStyle(PlainButtonStyle())
                }

                HStack {
                    ForEach(weekdaySymbols, id: \.self) { s in
                        Text(s).font(NRFont.tiny).foregroundColor(NRColor.textMuted).frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                    ForEach(Array(monthGrid.enumerated()), id: \.offset) { _, day in
                        if let day = day {
                            dayCell(day)
                        } else {
                            Color.clear.frame(height: 40)
                        }
                    }
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = cal.isDate(date, inSameDayAs: selected)
        let isToday = cal.isDateInToday(date)
        let hasEvents = store.hasEvents(on: date)
        return Button {
            Haptics.tap(); withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selected = date }
        } label: {
            VStack(spacing: 3) {
                Text("\(cal.component(.day, from: date))")
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? NRColor.onAccent : (isToday ? NRColor.accentDeep : NRColor.textPrimary))
                Circle()
                    .fill(hasEvents ? (isSelected ? NRColor.onAccent : NRColor.accent) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity).frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? AnyColor.accentFill : (isToday ? NRColor.accent.opacity(0.12) : Color.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: Day feed

    private var dayFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NRFormat.relativeDay(selected)).font(NRFont.title2).foregroundColor(NRColor.textPrimary)
                Spacer()
                Button { Haptics.tap(); showAddReminder = true } label: {
                    Label("Reminder", systemImage: "plus").font(NRFont.callout).foregroundColor(NRColor.accentDeep)
                }
            }
            let events = store.events(on: selected)
            if events.isEmpty {
                NRCard {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar").foregroundColor(NRColor.textMuted)
                        Text("Nothing scheduled this day.").font(NRFont.callout).foregroundColor(NRColor.textMuted)
                        Spacer()
                    }
                }
            } else {
                ForEach(events) { event in EventRow(event: event) }
            }
        }
    }

    // MARK: Helpers

    private func changeMonth(_ delta: Int) {
        Haptics.tap()
        if let m = cal.date(byAdding: .month, value: delta, to: month) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { month = cal.startOfMonth(for: m) }
        }
    }

    private var monthGrid: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: month) else { return [] }
        let firstWeekday = cal.component(.weekday, from: month) // 1 = Sunday
        let leading = settings.weekStartsMonday ? (firstWeekday + 5) % 7 : firstWeekday - 1
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: month) { cells.append(date) }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}

struct EventRow: View {
    let event: CalendarEvent
    var body: some View {
        NRCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(event.color.opacity(0.16)).frame(width: 42, height: 42)
                    Image(systemName: event.icon).foregroundColor(event.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title).font(NRFont.headline).foregroundColor(NRColor.textPrimary).lineLimit(1)
                    if !event.subtitle.isEmpty {
                        Text(event.subtitle).font(NRFont.caption).foregroundColor(NRColor.textMuted).lineLimit(1)
                    }
                }
                Spacer()
                Text(NRFormat.time.string(from: event.date)).font(NRFont.caption).foregroundColor(NRColor.textSecondary)
            }
        }
    }
}

// Helper to allow a gradient fill on a RoundedRectangle background.
enum AnyColor {
    static var accentFill: Color { NRColor.accent }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
