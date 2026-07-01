//
//  DashboardView.swift
//  NestRoute
//
//  Home screen (Экран 6): main stats, featured active route, quick actions,
//  warnings and tasks — a hub linking out to every other section.
//

import SwiftUI

struct DashboardView: View {
    var selectTab: (AppTab) -> Void
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var settings: AppSettings

    @State private var showSettings = false
    @State private var showAddRoute = false
    @State private var showAddGroup = false

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Good night"
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                NRBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: NRSpacing.lg) {
                        NRHeaderBar(title: greeting,
                                    subtitle: NRFormat.weekdayDayMonth.string(from: Date()),
                                    trailingIcon: "gearshape.fill",
                                    trailingAction: { showSettings = true })

                        statsGrid
                        featuredRoute
                        quickActions
                        warningsSection
                        tasksSection
                        weeklyCard
                        shortcutsRow

                        TabBarSpacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showAddRoute) { AddRouteView() }
            .sheet(isPresented: $showAddGroup) { AddGroupView() }
        }
        .nrStackNavigation()
    }

    // MARK: Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            StatTile(icon: "leaf.fill", tint: NRColor.accent,
                     value: "\(store.totalBirds)", label: "Birds tracked",
                     spark: store.weeklyMovement.map { $0.value },
                     customIcon: AnyView(BirdGlyph(size: 20, color: NRColor.accent)))
            StatTile(icon: "map.fill", tint: NRColor.blue,
                     value: "\(store.activeRoutes.count)", label: "Active routes",
                     spark: [2, 3, 2, 4, 3, 5, store.activeRoutes.count == 0 ? 1 : Double(store.activeRoutes.count)])
            StatTile(icon: "shippingbox.fill", tint: NRColor.gold,
                     value: "\(store.birdsInTransit)", label: "In transit",
                     spark: store.weeklyMovement.map { $0.value * 0.6 })
            StatTile(icon: "heart.fill", tint: NRColor.danger,
                     value: "\(Int(store.averageWelfare))%", label: "Avg welfare",
                     spark: store.welfareTrend.map { $0.value })
        }
    }

    // MARK: Featured route

    @ViewBuilder private var featuredRoute: some View {
        if let route = store.activeRoutes.first ?? store.routes.first(where: { $0.status != .completed }) {
            NavigationLink(destination: RoutePlannerView(routeId: route.id)) {
                NRCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Featured route", systemImage: "star.fill")
                                .font(NRFont.caption)
                                .foregroundColor(NRColor.gold)
                            Spacer()
                            StatusBadge(text: route.status.title, color: route.status.color)
                        }
                        Text(route.name)
                            .font(NRFont.title2)
                            .foregroundColor(NRColor.textPrimary)
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill").font(.system(size: 11)).foregroundColor(NRColor.accent)
                            Text("\(route.origin)  →  \(route.destination)")
                                .font(NRFont.callout)
                                .foregroundColor(NRColor.textMuted)
                                .lineLimit(1)
                        }
                        HStack {
                            miniMetric("flag.fill", settings.formattedDistance(route.distanceKm))
                            Spacer()
                            miniMetric("clock.fill", String(format: "%.1f h", route.estimatedHours))
                            Spacer()
                            miniMetric("heart.fill", "\(Int(route.welfare))%")
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(NRColor.textMuted)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func miniMetric(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundColor(NRColor.accent)
            Text(text).font(NRFont.callout).foregroundColor(NRColor.textSecondary)
        }
    }

    // MARK: Quick actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick actions")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                QuickActionTile(icon: "plus.circle.fill", title: "Plan route", tint: NRColor.accent) { showAddRoute = true }
                QuickActionTile(icon: "leaf.fill", title: "Add group", tint: NRColor.blue,
                                customIcon: AnyView(BirdGlyph(size: 20, color: NRColor.blue))) { showAddGroup = true }
                NavigationLink(destination: CalendarView()) {
                    QuickActionTileLabel(icon: "calendar", title: "Calendar", tint: NRColor.gold)
                }.buttonStyle(PlainButtonStyle())
                NavigationLink(destination: NotificationsView()) {
                    QuickActionTileLabel(icon: "bell.fill", title: "Reminders", tint: NRColor.danger)
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: Warnings

    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Warnings")
            if store.warnings.isEmpty {
                NRCard {
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 26)).foregroundColor(NRColor.ok)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("All clear").font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                            Text("No welfare or schedule issues right now.")
                                .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                        }
                        Spacer()
                    }
                }
            } else {
                ForEach(store.warnings) { w in
                    WarningRow(rec: w)
                }
            }
        }
    }

    // MARK: Tasks

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tasks").font(NRFont.title2).foregroundColor(NRColor.textPrimary)
                Spacer()
                NavigationLink(destination: TasksView()) {
                    Text("See all").font(NRFont.callout).foregroundColor(NRColor.accentDeep)
                }
            }
            if store.openTasks.isEmpty {
                NRCard {
                    Text("No open tasks. Nicely done! 🐦")
                        .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(store.openTasks.prefix(3)) { task in
                    TaskRow(task: task) { store.toggleTask(task) }
                }
            }
        }
    }

    // MARK: Weekly card

    private var weeklyCard: some View {
        NRCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Bird movement this week")
                        .font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Spacer()
                    Image(systemName: "chart.bar.fill").foregroundColor(NRColor.accent)
                }
                BarChartView(points: store.weeklyMovement, tint: NRColor.accent, height: 140)
            }
        }
    }

    // MARK: Shortcuts

    private var shortcutsRow: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: RecommendationsView()) {
                ShortcutChip(icon: "lightbulb.fill", title: "Tips", tint: NRColor.gold)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: HistoryView()) {
                ShortcutChip(icon: "clock.arrow.circlepath", title: "History", tint: NRColor.blue)
            }.buttonStyle(PlainButtonStyle())
            Button { Haptics.tap(); selectTab(.reports) } label: {
                ShortcutChip(icon: "chart.bar.xaxis", title: "Reports", tint: NRColor.accent)
            }.buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let icon: String
    let tint: Color
    let value: String
    let label: String
    var spark: [Double] = []
    var customIcon: AnyView? = nil

    var body: some View {
        NRCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.opacity(0.15))
                        .frame(width: 38, height: 38)
                    if let customIcon = customIcon {
                        customIcon
                    } else {
                        Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundColor(tint)
                    }
                }
                Text(value)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(NRColor.textPrimary)
                Text(label)
                    .font(NRFont.caption)
                    .foregroundColor(NRColor.textMuted)
                if !spark.isEmpty {
                    Sparkline(values: spark, tint: tint).frame(height: 22)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Quick action tiles

struct QuickActionTileLabel: View {
    let icon: String
    let title: String
    let tint: Color
    var customIcon: AnyView? = nil
    var body: some View {
        NRCard(padding: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(tint.opacity(0.15)).frame(width: 40, height: 40)
                    if let customIcon = customIcon {
                        customIcon
                    } else {
                        Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundColor(tint)
                    }
                }
                Text(title).font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                Spacer()
            }
        }
    }
}

struct QuickActionTile: View {
    let icon: String
    let title: String
    let tint: Color
    var customIcon: AnyView? = nil
    let action: () -> Void
    var body: some View {
        Button { Haptics.tap(); action() } label: {
            QuickActionTileLabel(icon: icon, title: title, tint: tint, customIcon: customIcon)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShortcutChip: View {
    let icon: String
    let title: String
    let tint: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundColor(tint)
            Text(title).font(NRFont.caption).foregroundColor(NRColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous).fill(NRColor.surface))
        .overlay(RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous).stroke(NRColor.hairline, lineWidth: 1))
    }
}

// MARK: - Warning row

struct WarningRow: View {
    let rec: Recommendation
    var body: some View {
        NRCard(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: rec.icon).font(.system(size: 18, weight: .bold)).foregroundColor(rec.color)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(rec.title).font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Text(rec.detail).font(NRFont.callout).foregroundColor(NRColor.textMuted)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Task row (reused across screens)

struct TaskRow: View {
    let task: TaskItem
    let toggle: () -> Void
    var body: some View {
        NRCard(padding: 14) {
            HStack(spacing: 12) {
                Button { Haptics.tap(); toggle() } label: {
                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(task.isDone ? NRColor.accent : NRColor.textMuted)
                }
                .buttonStyle(PlainButtonStyle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(NRFont.headline)
                        .foregroundColor(NRColor.textPrimary)
                        .strikethrough(task.isDone, color: NRColor.textMuted)
                    Text(NRFormat.relativeDay(task.due) + " · " + NRFormat.time.string(from: task.due))
                        .font(NRFont.caption).foregroundColor(NRColor.textMuted)
                }
                Spacer()
                Image(systemName: task.priority.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(task.priority.color)
                    .padding(6)
                    .background(Circle().fill(task.priority.color.opacity(0.15)))
            }
        }
    }
}
