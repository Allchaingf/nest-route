//
//  AppSettings.swift
//  NestRoute
//
//  App-wide preferences (theme, units, notifications, haptics) backed by
//  UserDefaults and published for live UI updates. Injected as an
//  @EnvironmentObject so every screen reacts instantly to a change.
//

import SwiftUI

// MARK: - Theme mode

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.fill"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Units

enum UnitSystem: String, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var distanceSuffix: String { self == .metric ? "km" : "mi" }
    var tempSuffix: String { self == .metric ? "°C" : "°F" }

    func distance(_ km: Double) -> Double { self == .metric ? km : km * 0.621371 }
    func temperature(_ celsius: Double) -> Double { self == .metric ? celsius : celsius * 9/5 + 32 }
}

// MARK: - Keys

private enum Keys {
    static let theme         = "nr.theme"
    static let units         = "nr.units"
    static let notifications = "nr.notifications"
    static let haptics       = "nr.haptics"
    static let weekMonday    = "nr.weekMonday"
    static let lastBackup    = "nr.lastBackup"
}

// MARK: - Haptics (gated by user preference)

enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard UserDefaults.standard.object(forKey: Keys.haptics) as? Bool ?? true else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        guard UserDefaults.standard.object(forKey: Keys.haptics) as? Bool ?? true else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Settings store

final class AppSettings: ObservableObject {

    @Published var themeMode: AppThemeMode {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: Keys.theme) }
    }
    @Published var units: UnitSystem {
        didSet { UserDefaults.standard.set(units.rawValue, forKey: Keys.units) }
    }
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notifications) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }
    @Published var weekStartsMonday: Bool {
        didSet { UserDefaults.standard.set(weekStartsMonday, forKey: Keys.weekMonday) }
    }
    @Published var lastBackup: Date? {
        didSet { UserDefaults.standard.set(lastBackup?.timeIntervalSince1970 ?? 0, forKey: Keys.lastBackup) }
    }

    init() {
        let d = UserDefaults.standard
        themeMode = AppThemeMode(rawValue: d.string(forKey: Keys.theme) ?? "") ?? .system
        units = UnitSystem(rawValue: d.string(forKey: Keys.units) ?? "") ?? .metric
        notificationsEnabled = d.object(forKey: Keys.notifications) as? Bool ?? true
        hapticsEnabled = d.object(forKey: Keys.haptics) as? Bool ?? true
        weekStartsMonday = d.object(forKey: Keys.weekMonday) as? Bool ?? true
        let backup = d.double(forKey: Keys.lastBackup)
        lastBackup = backup > 0 ? Date(timeIntervalSince1970: backup) : nil
    }

    var colorScheme: ColorScheme? { themeMode.colorScheme }

    func formattedDistance(_ km: Double) -> String {
        String(format: "%.0f %@", units.distance(km), units.distanceSuffix)
    }
    func formattedTemperature(_ celsius: Double) -> String {
        String(format: "%.0f%@", units.temperature(celsius), units.tempSuffix)
    }
}
