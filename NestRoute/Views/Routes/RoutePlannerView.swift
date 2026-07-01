//
//  RoutePlannerView.swift
//  NestRoute
//
//  The main screen (Экран 9 — Route Planner). Shows key data, live status
//  control, welfare charts and the activity timeline for a single route.
//  Reads the route live from the store so every edit reflects instantly.
//

import SwiftUI

struct RoutePlannerView: View {
    let routeId: UUID
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var settings: AppSettings

    @State private var showEdit = false
    @State private var showAddRecord = false
    @State private var showAddStop = false

    private var route: TransportRoute? { store.routes.first { $0.id == routeId } }

    var body: some View {
        ZStack {
            NRBackground()
            if let route = route {
                content(route)
            } else {
                EmptyStateView(icon: "map", title: "Route unavailable",
                               message: "This route was removed.")
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddRecord) { AddRecordView(routeId: routeId) }
        .sheet(isPresented: $showAddStop) { AddStopView(defaultRouteId: routeId) }
        .sheet(isPresented: $showEdit) {
            if let route = route { AddRouteView(route: route) }
        }
    }

    private func content(_ route: TransportRoute) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: NRSpacing.lg) {
                NRHeaderBar(title: route.name,
                            subtitle: "\(route.origin) → \(route.destination)",
                            showBack: true,
                            trailingIcon: "square.and.pencil",
                            trailingAction: { showEdit = true })

                statusControl(route)
                overviewCard(route)
                progressAndWelfare(route)
                if route.records.count >= 2 { welfareChart(route) }
                groupsSection(route)
                stopsSection(route)
                activitySection(route)
                actionLinks(route)

                TabBarSpacer()
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Status control

    private func statusControl(_ route: TransportRoute) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status").font(NRFont.caption).foregroundColor(NRColor.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RouteStatus.allCases) { status in
                        Button {
                            Haptics.tap(); store.setStatus(status, for: route)
                        } label: {
                            TagPill(text: status.title, icon: status.icon, selected: route.status == status)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: Overview

    private func overviewCard(_ route: TransportRoute) -> some View {
        NRCard {
            VStack(spacing: 12) {
                InfoRow(icon: "ruler", label: "Distance", value: settings.formattedDistance(route.distanceKm), tint: NRColor.blue)
                InfoRow(icon: "clock.fill", label: "Est. time", value: String(format: "%.1f h", route.estimatedHours), tint: NRColor.gold)
                InfoRow(icon: "arrow.up.right.circle.fill", label: "Departure", value: NRFormat.dateTime(route.departure), tint: NRColor.accent)
                InfoRow(icon: "flag.fill", label: "Arrival", value: NRFormat.dateTime(route.arrival), tint: NRColor.accentDeep)
                InfoRow(icon: "leaf.fill", label: "Birds", value: "\(store.birds(in: route))", tint: NRColor.danger,
                        customIcon: AnyView(BirdGlyph(size: 16, color: NRColor.danger)))
            }
        }
    }

    // MARK: Progress + welfare ring

    private func progressAndWelfare(_ route: TransportRoute) -> some View {
        NRCard {
            HStack(spacing: 18) {
                RingProgress(value: route.welfare / 100, size: 110, lineWidth: 13,
                             tint: route.welfare < 70 ? NRColor.warn : NRColor.accent,
                             label: "\(Int(route.welfare))%", caption: "welfare")
                VStack(alignment: .leading, spacing: 10) {
                    Text("Trip progress").font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    progressBar(route)
                    Text(progressText(route))
                        .font(NRFont.caption).foregroundColor(NRColor.textMuted)
                }
            }
        }
    }

    private func progressBar(_ route: TransportRoute) -> some View {
        let p = tripProgress(route)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(NRColor.hairline).frame(height: 10)
                Capsule().fill(NRGradient.brand).frame(width: geo.size.width * CGFloat(p), height: 10)
            }
        }
        .frame(height: 10)
    }

    private func tripProgress(_ route: TransportRoute) -> Double {
        switch route.status {
        case .planned: return 0.05
        case .active: break
        case .resting: return 0.5
        case .delayed: return 0.4
        case .completed: return 1
        }
        let total = route.arrival.timeIntervalSince(route.departure)
        guard total > 0 else { return 0.5 }
        let done = Date().timeIntervalSince(route.departure)
        return min(max(done / total, 0.05), 0.95)
    }
    private func progressText(_ route: TransportRoute) -> String {
        switch route.status {
        case .completed: return "Arrived safely at \(route.destination)."
        case .planned: return "Departs \(NRFormat.relativeDay(route.departure))."
        case .delayed: return "Delayed — review welfare and schedule."
        default: return "\(Int(tripProgress(route) * 100))% of the journey complete."
        }
    }

    // MARK: Welfare chart

    private func welfareChart(_ route: TransportRoute) -> some View {
        NRCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Welfare activity").font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                LineChartView(points: route.records.sorted { $0.date < $1.date }.map {
                    ChartPoint(label: NRFormat.time.string(from: $0.date), value: $0.value)
                }, tint: NRColor.accent, height: 160)
            }
        }
    }

    // MARK: Groups

    private func groupsSection(_ route: TransportRoute) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Bird groups")
            let groups = store.groups(for: route)
            if groups.isEmpty {
                NRCard { Text("No groups attached. Edit the route to add some.")
                    .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading) }
            } else {
                ForEach(groups) { group in
                    NavigationLink(destination: GroupDetailView(groupId: group.id)) {
                        GroupRow(group: group)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: Stops

    private func stopsSection(_ route: TransportRoute) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Stops").font(NRFont.title2).foregroundColor(NRColor.textPrimary)
                Spacer()
                Button { Haptics.tap(); showAddStop = true } label: {
                    Label("Add", systemImage: "plus").font(NRFont.callout).foregroundColor(NRColor.accentDeep)
                }
            }
            if route.stops.isEmpty {
                NRCard { Text("No stops planned. Add rest and watering points.")
                    .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading) }
            } else {
                ForEach(route.stops) { stop in
                    StopRow(stop: stop) { store.deleteStop(stop.id, from: route.id) }
                }
            }
        }
    }

    // MARK: Activity

    private func activitySection(_ route: TransportRoute) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity").font(NRFont.title2).foregroundColor(NRColor.textPrimary)
                Spacer()
                Button { Haptics.tap(); showAddRecord = true } label: {
                    Label("Record", systemImage: "plus").font(NRFont.callout).foregroundColor(NRColor.accentDeep)
                }
            }
            if route.records.isEmpty {
                NRCard { Text("No records yet. Log welfare at each checkpoint.")
                    .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading) }
            } else {
                ForEach(route.records) { record in
                    RecordRow(record: record) { store.deleteRecord(record, from: route.id) }
                }
            }
        }
    }

    // MARK: Action links

    private func actionLinks(_ route: TransportRoute) -> some View {
        VStack(spacing: 12) {
            NavigationLink(destination: RouteDetailsView(routeId: route.id)) {
                ActionLinkRow(icon: "doc.text.fill", title: "Full details", tint: NRColor.blue)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: TrendsView(routeId: route.id)) {
                ActionLinkRow(icon: "chart.bar.xaxis", title: "Trends & charts", tint: NRColor.accent)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: RecommendationsView()) {
                ActionLinkRow(icon: "lightbulb.fill", title: "Recommendations", tint: NRColor.gold)
            }.buttonStyle(PlainButtonStyle())
            PrimaryButton(title: "Add welfare record", icon: "plus") { showAddRecord = true }
        }
    }
}

// MARK: - Reusable rows

struct GroupRow: View {
    let group: BirdGroup
    var body: some View {
        NRCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(group.category.color.opacity(0.16)).frame(width: 42, height: 42)
                    Image(systemName: group.category.icon).foregroundColor(group.category.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name).font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Text("\(group.category.title) · \(group.count) birds")
                        .font(NRFont.caption).foregroundColor(NRColor.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(NRColor.textMuted)
            }
        }
    }
}

struct StopRow: View {
    let stop: RouteStop
    var onDelete: (() -> Void)? = nil
    var body: some View {
        NRCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(stop.type.color.opacity(0.16)).frame(width: 42, height: 42)
                    Image(systemName: stop.type.icon).foregroundColor(stop.type.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(stop.name).font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Text("\(stop.type.title) · \(stop.durationMin) min")
                        .font(NRFont.caption).foregroundColor(NRColor.textMuted)
                }
                Spacer()
                if let onDelete = onDelete {
                    Button { Haptics.tap(); onDelete() } label: {
                        Image(systemName: "trash").foregroundColor(NRColor.danger)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct RecordRow: View {
    let record: RouteRecord
    var onDelete: (() -> Void)? = nil
    var body: some View {
        NRCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: record.status.icon).font(.system(size: 18)).foregroundColor(record.status.color)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Welfare \(Int(record.value))%").font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                        StatusBadge(text: record.status.title, color: record.status.color)
                    }
                    Text(NRFormat.dateTime(record.date) + (record.note.isEmpty ? "" : " · \(record.note)"))
                        .font(NRFont.caption).foregroundColor(NRColor.textMuted)
                }
                Spacer()
                if let onDelete = onDelete {
                    Button { Haptics.tap(); onDelete() } label: {
                        Image(systemName: "trash").foregroundColor(NRColor.danger)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct ActionLinkRow: View {
    let icon: String
    let title: String
    let tint: Color
    var body: some View {
        NRCard(padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(tint.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: icon).foregroundColor(tint)
                }
                Text(title).font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(NRColor.textMuted)
            }
        }
    }
}
