//
//  NotificationsView.swift
//  NestRoute
//
//  Notifications section (Экран 18 — Reminders). Manages real local
//  notifications: request permission, schedule / toggle / delete reminders
//  and send a test banner.
//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var notifications: NotificationManager
    @State private var showAdd = false
    @State private var toast: String?

    private var authorized: Bool {
        notifications.authorization == .authorized || notifications.authorization == .provisional
    }

    var body: some View {
        ZStack {
            NRBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: NRSpacing.md) {
                    NRHeaderBar(title: "Reminders", subtitle: "Welfare & schedule alerts", showBack: true,
                                trailingIcon: "plus", trailingAction: { tryAdd() })

                    permissionCard

                    if store.reminders.isEmpty {
                        EmptyStateView(icon: "bell.slash",
                                       title: "No reminders",
                                       message: "Schedule reminders for welfare checks and departures.",
                                       actionTitle: "Add reminder") { tryAdd() }
                    } else {
                        SectionHeader(title: "Scheduled")
                        ForEach(store.reminders) { reminder in
                            ReminderRow(reminder: reminder,
                                        toggle: { store.toggleReminder(reminder) },
                                        delete: { store.deleteReminder(reminder) })
                        }
                    }

                    if authorized {
                        SecondaryButton(title: "Send a test notification", icon: "paperplane.fill") {
                            notifications.fireTest()
                            withAnimation { toast = "Test notification scheduled" }
                        }
                        .padding(.top, 4)
                    }

                    TabBarSpacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear { notifications.refreshStatus() }
        .sheet(isPresented: $showAdd) { AddReminderView(defaultDate: Date().addingTimeInterval(3600)) }
        .nrToast(message: $toast)
    }

    private var permissionCard: some View {
        NRCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill((authorized ? NRColor.ok : NRColor.warn).opacity(0.16)).frame(width: 46, height: 46)
                    Image(systemName: authorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(authorized ? NRColor.ok : NRColor.warn)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(authorized ? "Notifications on" : "Notifications off")
                        .font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Text(authorized ? "Reminders will alert you on time."
                                    : "Allow notifications to receive reminders.")
                        .font(NRFont.caption).foregroundColor(NRColor.textMuted)
                }
                Spacer()
                if !authorized {
                    Button { requestPermission() } label: {
                        Text("Allow").font(NRFont.callout).foregroundColor(NRColor.onAccent)
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(Capsule().fill(NRGradient.brand))
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func requestPermission() {
        notifications.requestAuthorization { granted in
            withAnimation { toast = granted ? "Notifications enabled" : "Permission denied" }
        }
    }

    private func tryAdd() {
        if !authorized { requestPermission() }
        showAdd = true
    }
}

struct ReminderRow: View {
    let reminder: ReminderItem
    let toggle: () -> Void
    let delete: () -> Void

    var body: some View {
        NRCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(NRColor.gold.opacity(0.16)).frame(width: 42, height: 42)
                    Image(systemName: "bell.fill").foregroundColor(NRColor.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title).font(NRFont.headline).foregroundColor(NRColor.textPrimary).lineLimit(1)
                    Text(NRFormat.dateTime(reminder.date)).font(NRFont.caption).foregroundColor(NRColor.textMuted)
                }
                Spacer()
                Toggle("", isOn: Binding(get: { reminder.isEnabled }, set: { _ in toggle() }))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: NRColor.accent))
            }
        }
        .contextMenu {
            Button { delete() } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

struct AddReminderView: View {
    var defaultDate: Date = Date().addingTimeInterval(3600)
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var notifications: NotificationManager
    @StateObject private var vm = AddReminderViewModel()

    var body: some View {
        FormScaffold(title: "New reminder", canSave: vm.isValid, onSave: save) {
            NRTextField(title: "Title", icon: "bell.fill", placeholder: "e.g. Welfare check", text: $vm.title)
            NRTextEditor(title: "Message", text: $vm.body)
            VStack(alignment: .leading, spacing: 6) {
                Text("When").font(NRFont.caption).foregroundColor(NRColor.textMuted)
                DatePicker("", selection: $vm.date)
                    .labelsHidden().datePickerStyle(GraphicalDatePickerStyle()).accentColor(NRColor.accent)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).fill(NRColor.surface))
                    .overlay(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).stroke(NRColor.hairline, lineWidth: 1))
            }
        }
        .onAppear {
            vm.date = defaultDate
            notifications.requestAuthorization()
        }
    }

    private func save() { store.addReminder(vm.build()) }
}
