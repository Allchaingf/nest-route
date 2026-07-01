//
//  SettingsView.swift
//  NestRoute
//
//  Settings (Экран 20): Theme, Units, Backup — plus notifications, haptics
//  and data reset. Every control has a real, persisted effect.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var notifications: NotificationManager
    @Environment(\.presentationMode) private var presentation

    @State private var toast: String?
    @State private var shareURL: ShareItem?
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            NRBackground()
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: NRSpacing.lg) {
                        appearanceSection
                        unitsSection
                        generalSection
                        notificationsSection
                        backupSection
                        aboutSection
                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
        }
        .preferredColorScheme(settings.colorScheme)
        .nrToast(message: $toast)
        .sheet(item: $shareURL) { item in ShareSheet(items: [item.url]) }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Settings").font(NRFont.title).foregroundColor(NRColor.textPrimary)
            Spacer()
            Button { Haptics.tap(); presentation.wrappedValue.dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundColor(NRColor.textMuted)
                    .frame(width: 38, height: 38).background(Circle().fill(NRColor.surface))
                    .overlay(Circle().stroke(NRColor.hairline, lineWidth: 1))
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 10)
    }

    // MARK: Appearance (Theme)

    private var appearanceSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush.fill") {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ForEach(AppThemeMode.allCases) { mode in
                        Button {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { settings.themeMode = mode }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: mode.icon).font(.system(size: 20, weight: .semibold))
                                Text(mode.title).font(NRFont.caption)
                            }
                            .foregroundColor(settings.themeMode == mode ? NRColor.onAccent : NRColor.textSecondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(themeChipBackground(selected: settings.themeMode == mode))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                Text("Theme applies instantly across the whole app and is remembered next launch.")
                    .font(NRFont.caption).foregroundColor(NRColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private func themeChipBackground(selected: Bool) -> some View {
        if selected {
            RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).fill(NRGradient.brand)
        } else {
            RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).fill(NRColor.surfaceAlt)
                .overlay(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).stroke(NRColor.hairline, lineWidth: 1))
        }
    }

    // MARK: Units

    private var unitsSection: some View {
        SettingsSection(title: "Units", icon: "ruler.fill") {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ForEach(UnitSystem.allCases) { unit in
                        Button {
                            Haptics.tap()
                            withAnimation { settings.units = unit }
                        } label: {
                            Text(unit.title)
                                .font(NRFont.headline)
                                .foregroundColor(settings.units == unit ? NRColor.onAccent : NRColor.textSecondary)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(themeChipBackground(selected: settings.units == unit))
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
                InfoRow(icon: "map.fill", label: "Example distance", value: settings.formattedDistance(180), tint: NRColor.blue)
                InfoRow(icon: "thermometer", label: "Example temp", value: settings.formattedTemperature(21), tint: NRColor.gold)
            }
        }
    }

    // MARK: General

    private var generalSection: some View {
        SettingsSection(title: "General", icon: "slider.horizontal.3") {
            VStack(spacing: 4) {
                ToggleRow(icon: "calendar", title: "Week starts Monday", tint: NRColor.accent,
                          isOn: $settings.weekStartsMonday)
                Divider().background(NRColor.hairline)
                ToggleRow(icon: "hand.tap.fill", title: "Haptic feedback", tint: NRColor.blue,
                          isOn: $settings.hapticsEnabled)
            }
        }
    }

    // MARK: Notifications

    private var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell.fill") {
            VStack(spacing: 10) {
                ToggleRow(icon: "bell.badge.fill", title: "Enable reminders", tint: NRColor.gold,
                          isOn: Binding(get: { settings.notificationsEnabled }, set: { on in
                              settings.notificationsEnabled = on
                              if on {
                                  notifications.requestAuthorization()
                                  store.reminders.filter { $0.isEnabled }.forEach { notifications.schedule($0) }
                                  toast = "Reminders enabled"
                              } else {
                                  notifications.cancelAll()
                                  toast = "Reminders paused"
                              }
                          }))
                Text(authText).font(NRFont.caption).foregroundColor(NRColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var authText: String {
        switch notifications.authorization {
        case .authorized, .provisional: return "System permission granted."
        case .denied: return "Blocked in iOS Settings — enable there to receive alerts."
        default: return "Permission will be requested when you add a reminder."
        }
    }

    // MARK: Backup

    private var backupSection: some View {
        SettingsSection(title: "Backup", icon: "externaldrive.fill") {
            VStack(spacing: 12) {
                InfoRow(icon: "clock.fill", label: "Last backup",
                        value: settings.lastBackup.map { NRFormat.fileStamp.string(from: $0) } ?? "Never",
                        tint: NRColor.accent)
                SecondaryButton(title: "Back up & export", icon: "square.and.arrow.up") { backupNow() }
                SecondaryButton(title: "Restore last backup", icon: "arrow.counterclockwise") { restore() }
                Button { Haptics.tap(.medium); showResetConfirm = true } label: {
                    HStack { Image(systemName: "trash"); Text("Reset to sample data") }
                        .font(NRFont.headline).foregroundColor(NRColor.danger)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous).fill(NRColor.danger.opacity(0.12)))
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .alert(isPresented: $showResetConfirm) {
            Alert(title: Text("Reset all data?"),
                  message: Text("This replaces your routes, groups and tasks with the sample set."),
                  primaryButton: .destructive(Text("Reset")) {
                      store.resetToSamples(); toast = "Sample data restored"
                  },
                  secondaryButton: .cancel())
        }
    }

    private var backupFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("nestroute_backup.json")
    }

    private func backupNow() {
        let data = store.snapshot()
        do {
            try data.write(to: backupFileURL, options: .atomic)
            settings.lastBackup = Date()
            shareURL = ShareItem(url: backupFileURL)
            toast = "Backup created"
        } catch {
            toast = "Backup failed"
        }
    }

    private func restore() {
        guard let data = try? Data(contentsOf: backupFileURL), store.restore(from: data) else {
            toast = "No backup found"; return
        }
        toast = "Backup restored"
    }

    // MARK: About

    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill") {
            VStack(spacing: 10) {
                InfoRow(icon: "app.badge.fill", label: "Version", value: appVersion, tint: NRColor.accent)
                Text("NestRoute helps you plan safe, low-stress transport routes for birds — tracking groups, stops, welfare and schedules in one place.")
                    .font(NRFont.caption).foregroundColor(NRColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "NestRoute \(v)"
    }
}

// MARK: - Settings building blocks

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.icon = icon; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(NRColor.accent)
                Text(title).font(NRFont.title2).foregroundColor(NRColor.textPrimary)
            }
            NRCard { content }
        }
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    let tint: Color
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(tint).frame(width: 26)
            Text(title).font(NRFont.body).foregroundColor(NRColor.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().toggleStyle(SwitchToggleStyle(tint: NRColor.accent))
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Share sheet

struct ShareItem: Identifiable { let id = UUID(); let url: URL }

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
