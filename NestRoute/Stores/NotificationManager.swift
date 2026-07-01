//
//  NotificationManager.swift
//  NestRoute
//
//  Thin wrapper around UNUserNotificationCenter for requesting permission
//  and scheduling / cancelling real local reminders.
//

import Foundation
import UserNotifications
import UIKit

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var authorization: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        refreshStatus()
    }

    func refreshStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { self.authorization = settings.authorizationStatus }
        }
    }

    func requestAuthorization(_ completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.refreshStatus()
                completion?(granted)
            }
        }
    }

    /// Schedule a reminder. Past dates fire a few seconds out so the user
    /// still gets confirmation that scheduling works.
    func schedule(_ reminder: ReminderItem) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body.isEmpty ? "NestRoute reminder" : reminder.body
        content.sound = .default

        let interval = reminder.date.timeIntervalSinceNow
        let trigger: UNNotificationTrigger
        if interval > 1 {
            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: reminder.date)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    func cancel(_ reminder: ReminderItem) {
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// Fire a short confirmation notification (used by the "test" action).
    func fireTest() {
        let content = UNMutableNotificationContent()
        content.title = "NestRoute"
        content.body = "Notifications are working. You'll be reminded about welfare checks."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        center.add(UNNotificationRequest(identifier: UUID().uuidString,
                                         content: content, trigger: trigger))
    }

    // Show banners while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
