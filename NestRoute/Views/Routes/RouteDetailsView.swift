//
//  RouteDetailsView.swift
//  NestRoute
//
//  Detailed read-only card for a route (Экран 10 — Details): full data,
//  notes, attached groups, stops and a welfare summary.
//

import SwiftUI

struct RouteDetailsView: View {
    let routeId: UUID
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var settings: AppSettings
    @State private var showEdit = false

    private var route: TransportRoute? { store.routes.first { $0.id == routeId } }

    var body: some View {
        ZStack {
            NRBackground()
            if let route = route {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: NRSpacing.lg) {
                        NRHeaderBar(title: "Details", subtitle: route.name, showBack: true,
                                    trailingIcon: "square.and.pencil", trailingAction: { showEdit = true })

                        // Hero
                        NRCard {
                            VStack(spacing: 14) {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(route.status.color.opacity(0.16)).frame(width: 54, height: 54)
                                        Image(systemName: route.status.icon).font(.system(size: 24)).foregroundColor(route.status.color)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(route.name).font(NRFont.title2).foregroundColor(NRColor.textPrimary)
                                        Text("\(route.origin) → \(route.destination)")
                                            .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                                    }
                                    Spacer()
                                }
                                HStack {
                                    detailStat("\(Int(route.welfare))%", "Welfare", NRColor.accent)
                                    Divider().frame(height: 36).background(NRColor.hairline)
                                    detailStat(settings.formattedDistance(route.distanceKm), "Distance", NRColor.blue)
                                    Divider().frame(height: 36).background(NRColor.hairline)
                                    detailStat("\(store.birds(in: route))", "Birds", NRColor.gold)
                                }
                            }
                        }

                        // Schedule
                        sectionCard("Schedule", icon: "calendar") {
                            InfoRow(icon: "arrow.up.right.circle.fill", label: "Departure", value: NRFormat.dateTime(route.departure), tint: NRColor.accent)
                            InfoRow(icon: "flag.fill", label: "Arrival", value: NRFormat.dateTime(route.arrival), tint: NRColor.accentDeep)
                            InfoRow(icon: "clock.fill", label: "Duration", value: String(format: "%.1f h", route.estimatedHours), tint: NRColor.gold)
                            InfoRow(icon: route.status.icon, label: "Status", value: route.status.title, tint: route.status.color)
                        }

                        // Groups
                        if !store.groups(for: route).isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Groups")
                                ForEach(store.groups(for: route)) { g in
                                    NavigationLink(destination: GroupDetailView(groupId: g.id)) { GroupRow(group: g) }
                                        .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }

                        // Stops
                        if !route.stops.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Stops")
                                ForEach(route.stops) { stop in StopRow(stop: stop) }
                            }
                        }

                        // Notes
                        if !route.notes.isEmpty {
                            sectionCard("Notes", icon: "note.text") {
                                Text(route.notes).font(NRFont.body).foregroundColor(NRColor.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        TabBarSpacer()
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                EmptyStateView(icon: "doc", title: "Not found", message: "This route was removed.")
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEdit) { if let route = route { AddRouteView(route: route) } }
    }

    private func detailStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundColor(color)
            Text(label).font(NRFont.caption).foregroundColor(NRColor.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionCard<C: View>(_ title: String, icon: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(NRColor.accent)
                Text(title).font(NRFont.title2).foregroundColor(NRColor.textPrimary)
            }
            NRCard { VStack(spacing: 12) { content() } }
        }
    }
}
