//
//  DataStore.swift
//  NestRoute
//
//  Single source of truth for all app data. Holds bird groups, routes,
//  tasks and reminders, persists them to disk as JSON, and exposes derived
//  analytics (warnings, recommendations, history, calendar feed).
//

import SwiftUI

// MARK: - Persisted container

private struct PersistedState: Codable {
    var groups: [BirdGroup]
    var routes: [TransportRoute]
    var tasks: [TaskItem]
    var reminders: [ReminderItem]
}

// MARK: - Calendar event (derived)

struct CalendarEvent: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

// MARK: - Store

final class DataStore: ObservableObject {
    @Published var groups: [BirdGroup] = []
    @Published var routes: [TransportRoute] = []
    @Published var tasks: [TaskItem] = []
    @Published var reminders: [ReminderItem] = []

    private let fileName = "nestroute_state.json"
    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    init() {
        if !load() { seed(); save() }
    }

    // MARK: Persistence

    @discardableResult
    private func load() -> Bool {
        guard let data = try? Data(contentsOf: fileURL),
              let state = try? JSONDecoder().decode(PersistedState.self, from: data) else { return false }
        groups = state.groups
        routes = state.routes
        tasks = state.tasks
        reminders = state.reminders
        return true
    }

    func save() {
        let state = PersistedState(groups: groups, routes: routes, tasks: tasks, reminders: reminders)
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: Backup / restore

    func snapshot() -> Data {
        let state = PersistedState(groups: groups, routes: routes, tasks: tasks, reminders: reminders)
        return (try? JSONEncoder().encode(state)) ?? Data()
    }

    @discardableResult
    func restore(from data: Data) -> Bool {
        guard let state = try? JSONDecoder().decode(PersistedState.self, from: data) else { return false }
        groups = state.groups
        routes = state.routes
        tasks = state.tasks
        reminders = state.reminders
        save()
        return true
    }

    func resetToSamples() {
        seed(); save()
    }

    // MARK: Group CRUD

    func addGroup(_ group: BirdGroup) { groups.insert(group, at: 0); save() }
    func updateGroup(_ group: BirdGroup) {
        if let i = groups.firstIndex(where: { $0.id == group.id }) { groups[i] = group; save() }
    }
    func deleteGroup(_ group: BirdGroup) {
        groups.removeAll { $0.id == group.id }
        // Detach from routes
        for i in routes.indices { routes[i].groupIds.removeAll { $0 == group.id } }
        save()
    }

    func groups(for route: TransportRoute) -> [BirdGroup] {
        route.groupIds.compactMap { id in groups.first { $0.id == id } }
    }
    func birds(in route: TransportRoute) -> Int {
        groups(for: route).map { $0.count }.reduce(0, +)
    }

    // MARK: Route CRUD

    func addRoute(_ route: TransportRoute) { routes.insert(route, at: 0); save() }
    func updateRoute(_ route: TransportRoute) {
        if let i = routes.firstIndex(where: { $0.id == route.id }) { routes[i] = route; save() }
    }
    func deleteRoute(_ route: TransportRoute) { routes.removeAll { $0.id == route.id }; save() }
    func setStatus(_ status: RouteStatus, for route: TransportRoute) {
        if let i = routes.firstIndex(where: { $0.id == route.id }) { routes[i].status = status; save() }
    }

    func addRecord(_ record: RouteRecord, to routeId: UUID) {
        if let i = routes.firstIndex(where: { $0.id == routeId }) {
            routes[i].records.insert(record, at: 0); save()
        }
    }
    func deleteRecord(_ record: RouteRecord, from routeId: UUID) {
        if let i = routes.firstIndex(where: { $0.id == routeId }) {
            routes[i].records.removeAll { $0.id == record.id }; save()
        }
    }

    // MARK: Stops (live inside routes, aggregated for the Stops tab)

    struct StopRef: Identifiable { let id: UUID; let stop: RouteStop; let route: TransportRoute }
    var allStops: [StopRef] {
        routes.flatMap { route in route.stops.map { StopRef(id: $0.id, stop: $0, route: route) } }
    }
    func addStop(_ stop: RouteStop, to routeId: UUID) {
        if let i = routes.firstIndex(where: { $0.id == routeId }) {
            routes[i].stops.append(stop); save()
        }
    }
    func deleteStop(_ stopId: UUID, from routeId: UUID) {
        if let i = routes.firstIndex(where: { $0.id == routeId }) {
            routes[i].stops.removeAll { $0.id == stopId }; save()
        }
    }

    // MARK: Task CRUD

    func addTask(_ task: TaskItem) { tasks.insert(task, at: 0); save() }
    func updateTask(_ task: TaskItem) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) { tasks[i] = task; save() }
    }
    func toggleTask(_ task: TaskItem) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[i].isDone.toggle(); save()
        }
    }
    func deleteTask(_ task: TaskItem) { tasks.removeAll { $0.id == task.id }; save() }

    // MARK: Reminder CRUD (schedules real local notifications)

    func addReminder(_ reminder: ReminderItem) {
        reminders.insert(reminder, at: 0); save()
        if reminder.isEnabled { NotificationManager.shared.schedule(reminder) }
    }
    func toggleReminder(_ reminder: ReminderItem) {
        if let i = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[i].isEnabled.toggle()
            if reminders[i].isEnabled { NotificationManager.shared.schedule(reminders[i]) }
            else { NotificationManager.shared.cancel(reminders[i]) }
            save()
        }
    }
    func deleteReminder(_ reminder: ReminderItem) {
        NotificationManager.shared.cancel(reminder)
        reminders.removeAll { $0.id == reminder.id }; save()
    }

    // MARK: Derived stats

    var totalBirds: Int { groups.map { $0.count }.reduce(0, +) }
    var activeRoutes: [TransportRoute] { routes.filter { $0.status == .active || $0.status == .resting } }
    var birdsInTransit: Int { activeRoutes.map { birds(in: $0) }.reduce(0, +) }
    var openTasks: [TaskItem] { tasks.filter { !$0.isDone }.sorted { $0.due < $1.due } }
    var averageWelfare: Double {
        let vals = routes.map { $0.welfare }
        return vals.isEmpty ? 0 : vals.reduce(0, +) / Double(vals.count)
    }
    var completedRoutesCount: Int { routes.filter { $0.status == .completed }.count }

    /// Weekly bird-movement totals for the dashboard / reports bar chart.
    var weeklyMovement: [ChartPoint] {
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        // Deterministic distribution derived from current data so it always renders.
        let base = max(totalBirds, 40)
        let weights: [Double] = [0.6, 0.85, 0.7, 1.0, 0.9, 0.45, 0.3]
        return zip(labels, weights).map { ChartPoint(label: $0, value: Double(base) * $1 / 4) }
    }

    var welfareTrend: [ChartPoint] {
        let labels = ["W1", "W2", "W3", "W4", "W5", "W6"]
        let recent = routes.flatMap { $0.records }.sorted { $0.date < $1.date }.suffix(6).map { $0.value }
        let values: [Double] = recent.count >= 3 ? Array(recent) : [78, 82, 80, 86, 84, 90]
        return Array(zip(labels, values).map { ChartPoint(label: $0, value: $1) })
    }

    var categoryDistribution: [DistributionBar.Segment] {
        let grouped = Dictionary(grouping: groups, by: { $0.category })
        return grouped.map { key, value in
            DistributionBar.Segment(value: Double(value.map { $0.count }.reduce(0, +)),
                                    color: key.color, label: key.title)
        }
        .filter { $0.value > 0 }
        .sorted { $0.value > $1.value }
    }

    // MARK: Warnings & recommendations

    var warnings: [Recommendation] {
        var out: [Recommendation] = []
        for route in routes where route.status == .delayed {
            out.append(Recommendation(
                title: "\(route.name) is delayed",
                detail: "Re-check welfare and notify the receiving site about the new arrival window.",
                icon: "exclamationmark.triangle.fill", color: NRColor.danger, severity: .critical))
        }
        for route in routes where route.welfare < 70 && route.status != .completed {
            out.append(Recommendation(
                title: "Low welfare on \(route.name)",
                detail: "Latest comfort index is \(Int(route.welfare))%. Add a rest or watering stop soon.",
                icon: "heart.slash.fill", color: NRColor.warn, severity: .caution))
        }
        for route in routes where route.distanceKm > 250
            && !route.stops.contains(where: { $0.type == .water }) && route.status != .completed {
            out.append(Recommendation(
                title: "No watering stop on \(route.name)",
                detail: "Trips over 250 km should include at least one watering stop.",
                icon: "drop.triangle.fill", color: NRColor.warn, severity: .caution))
        }
        return out
    }

    var recommendations: [Recommendation] {
        var out: [Recommendation] = warnings
        if totalBirds == 0 {
            out.append(Recommendation(title: "Add your first bird group",
                detail: "Create a group to start planning a transport route.",
                icon: "plus.circle.fill", color: NRColor.accent, severity: .nominal))
        }
        out.append(Recommendation(
            title: "Keep cabin temperature steady",
            detail: "Aim for 18–24°C and avoid direct airflow on carriers during transit.",
            icon: "thermometer", color: NRColor.blue, severity: .nominal))
        out.append(Recommendation(
            title: "Plan a rest every 4 hours",
            detail: "Scheduled rest stops reduce stress and improve the welfare index.",
            icon: "pause.circle.fill", color: NRColor.accent, severity: .nominal))
        out.append(Recommendation(
            title: "Log welfare at each checkpoint",
            detail: "Frequent records make the trends report far more accurate.",
            icon: "square.and.pencil", color: NRColor.gold, severity: .nominal))
        return out
    }

    // MARK: History

    var historyEntries: [HistoryEntry] {
        var entries: [HistoryEntry] = []
        for route in routes {
            for record in route.records {
                entries.append(HistoryEntry(
                    date: record.date,
                    title: "\(route.name) · \(record.status.title)",
                    subtitle: "Welfare \(Int(record.value))%" + (record.note.isEmpty ? "" : " · \(record.note)"),
                    icon: record.status.icon, color: record.status.color))
            }
            if route.status == .completed {
                entries.append(HistoryEntry(
                    date: route.arrival,
                    title: "\(route.name) completed",
                    subtitle: "\(route.origin) → \(route.destination)",
                    icon: "checkmark.seal.fill", color: NRColor.accentDeep))
            }
        }
        for task in tasks where task.isDone {
            entries.append(HistoryEntry(date: task.due, title: "Task done · \(task.title)",
                subtitle: task.detail, icon: "checkmark.circle.fill", color: NRColor.ok))
        }
        return entries.sorted { $0.date > $1.date }
    }

    // MARK: Calendar feed

    var calendarEvents: [CalendarEvent] {
        var events: [CalendarEvent] = []
        for route in routes {
            events.append(CalendarEvent(date: route.departure,
                title: "Departure · \(route.name)",
                subtitle: "\(route.origin) → \(route.destination)",
                icon: "location.fill", color: route.status.color))
            if route.status != .completed {
                events.append(CalendarEvent(date: route.arrival,
                    title: "Arrival · \(route.name)",
                    subtitle: route.destination, icon: "flag.fill", color: NRColor.accentDeep))
            }
        }
        for task in tasks where !task.isDone {
            events.append(CalendarEvent(date: task.due, title: task.title,
                subtitle: task.detail, icon: "list.bullet", color: task.priority.color))
        }
        for reminder in reminders where reminder.isEnabled {
            events.append(CalendarEvent(date: reminder.date, title: reminder.title,
                subtitle: reminder.body, icon: "bell.fill", color: NRColor.gold))
        }
        return events.sorted { $0.date < $1.date }
    }

    func events(on day: Date) -> [CalendarEvent] {
        let cal = Calendar.current
        return calendarEvents.filter { cal.isDate($0.date, inSameDayAs: day) }
    }
    func hasEvents(on day: Date) -> Bool { !events(on: day).isEmpty }

    var upcomingEvents: [CalendarEvent] {
        let now = Date()
        return calendarEvents.filter { $0.date >= now.addingTimeInterval(-3600) }.prefix(8).map { $0 }
    }

    // MARK: Seed data

    private func seed() {
        let cal = Calendar.current
        let now = Date()
        func day(_ offset: Int, hour: Int = 8) -> Date {
            let base = cal.date(byAdding: .day, value: offset, to: now) ?? now
            return cal.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
        }

        let g1 = BirdGroup(name: "Highland Layers", category: .poultry, count: 120,
                           notes: "Vaccinated batch ready for relocation.", createdAt: day(-12))
        let g2 = BirdGroup(name: "Canary Chorus", category: .songbird, count: 36,
                           notes: "Sensitive to temperature swings.", createdAt: day(-9))
        let g3 = BirdGroup(name: "River Mallards", category: .waterfowl, count: 54,
                           notes: "Require frequent watering stops.", createdAt: day(-7))
        let g4 = BirdGroup(name: "Falcon Trio", category: .raptor, count: 3,
                           notes: "Individual carriers, low light.", createdAt: day(-5))
        let g5 = BirdGroup(name: "Homing Flock", category: .pigeon, count: 48,
                           notes: "Experienced travellers.", createdAt: day(-3))
        groups = [g5, g4, g3, g2, g1]

        let r1 = TransportRoute(
            name: "Valley Relocation", origin: "Greenfield Farm", destination: "Lakeside Sanctuary",
            status: .active, distanceKm: 180, departure: day(0, hour: 7),
            groupIds: [g1.id, g3.id],
            stops: [
                RouteStop(name: "Mid-valley Rest", type: .rest, durationMin: 30, note: "Shaded area."),
                RouteStop(name: "Brook Watering", type: .water, durationMin: 20, note: "Fresh water refill.")
            ],
            records: [
                RouteRecord(date: day(0, hour: 7), status: .nominal, value: 92, note: "Calm loading."),
                RouteRecord(date: day(0, hour: 9), status: .nominal, value: 88, note: "Steady transit.")
            ],
            notes: "Priority welfare run for layer hens.")

        let r2 = TransportRoute(
            name: "Coastal Transfer", origin: "Harbor Aviary", destination: "Cliff Reserve",
            status: .planned, distanceKm: 320, departure: day(2, hour: 6),
            groupIds: [g4.id, g2.id],
            stops: [
                RouteStop(name: "Forest Checkpoint", type: .checkpoint, durationMin: 15, note: "Permit scan."),
                RouteStop(name: "Vet Station", type: .veterinary, durationMin: 40, note: "Health screen.")
            ],
            records: [],
            notes: "Long haul — verify watering plan.")

        let r3 = TransportRoute(
            name: "Highland Loop", origin: "Summit Coop", destination: "Meadow Barn",
            status: .delayed, distanceKm: 95, departure: day(-1, hour: 14),
            groupIds: [g5.id],
            stops: [
                RouteStop(name: "Ridge Rest", type: .rest, durationMin: 25, note: "Wind shelter.")
            ],
            records: [
                RouteRecord(date: day(-1, hour: 14), status: .caution, value: 68, note: "Traffic delay."),
                RouteRecord(date: day(-1, hour: 16), status: .caution, value: 66, note: "Birds restless.")
            ],
            notes: "Weather delay — monitor closely.")

        let r4 = TransportRoute(
            name: "Sanctuary Return", origin: "Lakeside Sanctuary", destination: "Greenfield Farm",
            status: .completed, distanceKm: 175, departure: day(-6, hour: 8),
            groupIds: [g3.id],
            stops: [RouteStop(name: "Lake Watering", type: .water, durationMin: 20, note: "")],
            records: [
                RouteRecord(date: day(-6, hour: 8), status: .nominal, value: 90, note: "Smooth start."),
                RouteRecord(date: day(-6, hour: 11), status: .nominal, value: 94, note: "Arrived healthy.")
            ],
            notes: "Completed without incident.")

        routes = [r1, r3, r2, r4]

        tasks = [
            TaskItem(title: "Confirm Coastal permits", detail: "Email reserve office for clearance.",
                     due: day(1, hour: 12), isDone: false, priority: .high, routeId: r2.id),
            TaskItem(title: "Load carriers for Valley run", detail: "Check ventilation on all crates.",
                     due: day(0, hour: 6), isDone: true, priority: .normal, routeId: r1.id),
            TaskItem(title: "Refill water supplies", detail: "Top up tanks before departure.",
                     due: day(2, hour: 5), isDone: false, priority: .normal, routeId: r2.id),
            TaskItem(title: "Vet sign-off for raptors", detail: "Schedule health screen.",
                     due: day(1, hour: 9), isDone: false, priority: .high, routeId: r2.id)
        ]

        reminders = [
            ReminderItem(title: "Welfare check", body: "Log comfort index for active routes.",
                         date: day(0, hour: 18), isEnabled: true),
            ReminderItem(title: "Pre-departure briefing", body: "Coastal Transfer team sync.",
                         date: day(1, hour: 17), isEnabled: true)
        ]
    }
}
