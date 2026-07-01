//
//  FormViewModels.swift
//  NestRoute
//
//  ObservableObject view models for the data-entry forms. Each owns its
//  @Published input fields, exposes live validation, and builds a clean
//  model object on save.
//

import SwiftUI

// MARK: - Bird group

final class AddGroupViewModel: ObservableObject {
    @Published var name = ""
    @Published var category: BirdCategory = .poultry
    @Published var countText = ""
    @Published var notes = ""

    let editing: BirdGroup?

    init(group: BirdGroup? = nil) {
        editing = group
        if let g = group {
            name = g.name; category = g.category; countText = "\(g.count)"; notes = g.notes
        }
    }

    var count: Int { Int(countText) ?? 0 }
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && count > 0 }

    func build() -> BirdGroup {
        BirdGroup(id: editing?.id ?? UUID(),
                  name: name.trimmingCharacters(in: .whitespaces),
                  category: category, count: count,
                  notes: notes,
                  createdAt: editing?.createdAt ?? Date())
    }
}

// MARK: - Route

final class AddRouteViewModel: ObservableObject {
    @Published var name = ""
    @Published var origin = ""
    @Published var destination = ""
    @Published var distanceText = ""
    @Published var departure = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var status: RouteStatus = .planned
    @Published var selectedGroupIds: Set<UUID> = []
    @Published var notes = ""

    let editing: TransportRoute?

    init(route: TransportRoute? = nil) {
        editing = route
        if let r = route {
            name = r.name; origin = r.origin; destination = r.destination
            distanceText = String(format: "%.0f", r.distanceKm)
            departure = r.departure; status = r.status
            selectedGroupIds = Set(r.groupIds); notes = r.notes
        }
    }

    var distance: Double { Double(distanceText) ?? 0 }
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !origin.trimmingCharacters(in: .whitespaces).isEmpty &&
        !destination.trimmingCharacters(in: .whitespaces).isEmpty &&
        distance > 0
    }

    func build() -> TransportRoute {
        TransportRoute(
            id: editing?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            origin: origin.trimmingCharacters(in: .whitespaces),
            destination: destination.trimmingCharacters(in: .whitespaces),
            status: status, distanceKm: distance, departure: departure,
            groupIds: Array(selectedGroupIds),
            stops: editing?.stops ?? [],
            records: editing?.records ?? [],
            notes: notes)
    }
}

// MARK: - Stop

final class AddStopViewModel: ObservableObject {
    @Published var name = ""
    @Published var type: StopType = .rest
    @Published var durationText = "30"
    @Published var note = ""
    @Published var routeId: UUID?

    init(defaultRouteId: UUID? = nil) { routeId = defaultRouteId }

    var duration: Int { Int(durationText) ?? 0 }
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && duration > 0 && routeId != nil
    }
    func build() -> RouteStop {
        RouteStop(name: name.trimmingCharacters(in: .whitespaces), type: type, durationMin: duration, note: note)
    }
}

// MARK: - Record

final class AddRecordViewModel: ObservableObject {
    @Published var date = Date()
    @Published var status: RecordStatus = .nominal
    @Published var value: Double = 85
    @Published var note = ""

    var isValid: Bool { value >= 0 && value <= 100 }

    func build() -> RouteRecord {
        RouteRecord(date: date, status: status, value: value, note: note)
    }
}

// MARK: - Task

final class AddTaskViewModel: ObservableObject {
    @Published var title = ""
    @Published var detail = ""
    @Published var due = Date().addingTimeInterval(3600)
    @Published var priority: TaskPriority = .normal
    @Published var routeId: UUID?

    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    func build() -> TaskItem {
        TaskItem(title: title.trimmingCharacters(in: .whitespaces), detail: detail,
                 due: due, isDone: false, priority: priority, routeId: routeId)
    }
}

// MARK: - Reminder

final class AddReminderViewModel: ObservableObject {
    @Published var title = ""
    @Published var body = ""
    @Published var date = Date().addingTimeInterval(3600)

    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    func build() -> ReminderItem {
        ReminderItem(title: title.trimmingCharacters(in: .whitespaces), body: body, date: date, isEnabled: true)
    }
}
