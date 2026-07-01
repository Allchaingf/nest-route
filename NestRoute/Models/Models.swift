//
//  Models.swift
//  NestRoute
//
//  Domain models for planning safe bird-transport routes: bird groups,
//  routes, stops, records, tasks and reminders. All Codable for persistence.
//

import SwiftUI

// MARK: - Bird category

enum BirdCategory: String, Codable, CaseIterable, Identifiable {
    case poultry, songbird, raptor, waterfowl, parrot, pigeon, gamebird, other
    var id: String { rawValue }

    var title: String {
        switch self {
        case .poultry:   return "Poultry"
        case .songbird:  return "Songbird"
        case .raptor:    return "Raptor"
        case .waterfowl: return "Waterfowl"
        case .parrot:    return "Parrot"
        case .pigeon:    return "Pigeon"
        case .gamebird:  return "Game bird"
        case .other:     return "Other"
        }
    }

    var icon: String {
        switch self {
        case .poultry:   return "house.fill"
        case .songbird:  return "music.note"
        case .raptor:    return "bolt.fill"
        case .waterfowl: return "drop.fill"
        case .parrot:    return "leaf.fill"
        case .pigeon:    return "paperplane.fill"
        case .gamebird:  return "hare.fill"
        case .other:     return "circle.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .poultry:   return NRColor.gold
        case .songbird:  return NRColor.cyan
        case .raptor:    return NRColor.danger
        case .waterfowl: return NRColor.blue
        case .parrot:    return NRColor.accent
        case .pigeon:    return NRColor.accentDeep
        case .gamebird:  return NRColor.goldDeep
        case .other:     return NRColor.textMuted
        }
    }
}

// MARK: - Route status

enum RouteStatus: String, Codable, CaseIterable, Identifiable {
    case planned, active, resting, delayed, completed
    var id: String { rawValue }

    var title: String {
        switch self {
        case .planned:   return "Planned"
        case .active:    return "In transit"
        case .resting:   return "Resting"
        case .delayed:   return "Delayed"
        case .completed: return "Completed"
        }
    }

    var icon: String {
        switch self {
        case .planned:   return "calendar"
        case .active:    return "location.fill"
        case .resting:   return "pause.circle.fill"
        case .delayed:   return "exclamationmark.triangle.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .planned:   return NRColor.blue
        case .active:    return NRColor.accent
        case .resting:   return NRColor.gold
        case .delayed:   return NRColor.danger
        case .completed: return NRColor.accentDeep
        }
    }
}

// MARK: - Stop type

enum StopType: String, Codable, CaseIterable, Identifiable {
    case rest, feeding, water, checkpoint, veterinary, border
    var id: String { rawValue }

    var title: String {
        switch self {
        case .rest:       return "Rest"
        case .feeding:    return "Feeding"
        case .water:      return "Watering"
        case .checkpoint: return "Checkpoint"
        case .veterinary: return "Vet check"
        case .border:     return "Border"
        }
    }

    var icon: String {
        switch self {
        case .rest:       return "pause.circle.fill"
        case .feeding:    return "tray.fill"
        case .water:      return "drop.fill"
        case .checkpoint: return "checkmark.shield.fill"
        case .veterinary: return "cross.case.fill"
        case .border:     return "flag.fill"
        }
    }

    var color: Color {
        switch self {
        case .rest:       return NRColor.gold
        case .feeding:    return NRColor.accent
        case .water:      return NRColor.cyan
        case .checkpoint: return NRColor.blue
        case .veterinary: return NRColor.danger
        case .border:     return NRColor.goldDeep
        }
    }
}

// MARK: - Record status

enum RecordStatus: String, Codable, CaseIterable, Identifiable {
    case nominal, caution, critical
    var id: String { rawValue }

    var title: String {
        switch self {
        case .nominal:  return "Nominal"
        case .caution:  return "Caution"
        case .critical: return "Critical"
        }
    }
    var icon: String {
        switch self {
        case .nominal:  return "checkmark.circle.fill"
        case .caution:  return "exclamationmark.circle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
    var color: Color {
        switch self {
        case .nominal:  return NRColor.ok
        case .caution:  return NRColor.warn
        case .critical: return NRColor.danger
        }
    }
}

// MARK: - Task priority

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low, normal, high
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .low:    return "arrow.down"
        case .normal: return "equal"
        case .high:   return "arrow.up"
        }
    }
    var color: Color {
        switch self {
        case .low:    return NRColor.ok
        case .normal: return NRColor.blue
        case .high:   return NRColor.danger
        }
    }
}

// MARK: - Records

struct RouteRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var status: RecordStatus
    var value: Double          // welfare / comfort index 0–100
    var note: String
}

// MARK: - Stops

struct RouteStop: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var type: StopType
    var durationMin: Int
    var note: String
}

// MARK: - Bird group

struct BirdGroup: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var category: BirdCategory
    var count: Int
    var notes: String
    var createdAt: Date
}

// MARK: - Transport route

struct TransportRoute: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var origin: String
    var destination: String
    var status: RouteStatus
    var distanceKm: Double
    var departure: Date
    var groupIds: [UUID]
    var stops: [RouteStop]
    var records: [RouteRecord]
    var notes: String

    /// Latest welfare value reported on this route (0–100).
    var welfare: Double {
        records.sorted { $0.date > $1.date }.first?.value ?? 80
    }

    /// Estimated travel time in hours based on a 65 km/h average plus stop time.
    var estimatedHours: Double {
        let driving = distanceKm / 65.0
        let stopHours = Double(stops.map { $0.durationMin }.reduce(0, +)) / 60.0
        return driving + stopHours
    }

    var arrival: Date {
        departure.addingTimeInterval(estimatedHours * 3600)
    }
}

// MARK: - Tasks

struct TaskItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var detail: String
    var due: Date
    var isDone: Bool
    var priority: TaskPriority
    var routeId: UUID?
}

// MARK: - Reminders (mirror of scheduled local notifications)

struct ReminderItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var body: String
    var date: Date
    var isEnabled: Bool
}

// MARK: - Derived history entry (display only)

struct HistoryEntry: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

// MARK: - Recommendation (advice feed)

struct Recommendation: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let color: Color
    let severity: RecordStatus
}
