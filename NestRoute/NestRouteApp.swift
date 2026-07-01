//
//  NestRouteApp.swift
//  NestRoute
//
//  App entry point. Wires up the shared environment objects (settings,
//  data store, notifications) and applies the user-selected color scheme
//  to the whole app.
//

import SwiftUI

@main
struct NestRouteApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var store = DataStore()
    @StateObject private var notifications = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
                .environmentObject(notifications)
                .preferredColorScheme(settings.colorScheme)
        }
    }
}
