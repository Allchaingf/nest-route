//
//  RoutesListView.swift
//  NestRoute
//
//  Routes section (Экран 7-style list): filterable list of transport routes,
//  each opening the Route Planner. Add / edit / delete all fully wired.
//

import SwiftUI

struct RoutesListView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var settings: AppSettings

    @State private var showAdd = false
    @State private var editing: TransportRoute?
    @State private var filter: RouteStatus?

    private var filtered: [TransportRoute] {
        guard let f = filter else { return store.routes }
        return store.routes.filter { $0.status == f }
    }

    var body: some View {
        NavigationView {
            ZStack {
                NRBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: NRSpacing.md) {
                        NRHeaderBar(title: "Routes",
                                    subtitle: "\(store.routes.count) planned · \(store.activeRoutes.count) active",
                                    trailingIcon: "plus", trailingAction: { showAdd = true })

                        filterBar

                        if filtered.isEmpty {
                            EmptyStateView(icon: "map",
                                           title: "No routes yet",
                                           message: "Plan a transport route to start tracking your birds safely.",
                                           actionTitle: "Plan route") { showAdd = true }
                        } else {
                            ForEach(filtered) { route in
                                NavigationLink(destination: RoutePlannerView(routeId: route.id)) {
                                    RouteCard(route: route, birds: store.birds(in: route))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button { editing = route } label: { Label("Edit", systemImage: "pencil") }
                                    Button { store.deleteRoute(route) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        TabBarSpacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddRouteView() }
            .sheet(item: $editing) { route in AddRouteView(route: route) }
        }
        .nrStackNavigation()
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button { Haptics.tap(); filter = nil } label: {
                    TagPill(text: "All", icon: "square.grid.2x2", selected: filter == nil)
                }.buttonStyle(PlainButtonStyle())
                ForEach(RouteStatus.allCases) { status in
                    Button { Haptics.tap(); filter = (filter == status ? nil : status) } label: {
                        TagPill(text: status.title, icon: status.icon, selected: filter == status)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Route card

struct RouteCard: View {
    let route: TransportRoute
    let birds: Int
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(route.status.color.opacity(0.16)).frame(width: 44, height: 44)
                        Image(systemName: route.status.icon).foregroundColor(route.status.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(route.name).font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                        Text("\(route.origin) → \(route.destination)")
                            .font(NRFont.caption).foregroundColor(NRColor.textMuted).lineLimit(1)
                    }
                    Spacer()
                    StatusBadge(text: route.status.title, color: route.status.color)
                }

                Divider().background(NRColor.hairline)

                HStack {
                    metric("ruler", settings.formattedDistance(route.distanceKm))
                    Spacer()
                    HStack(spacing: 5) {
                        BirdGlyph(size: 12, color: NRColor.accent)
                        Text("\(birds)").font(NRFont.callout).foregroundColor(NRColor.textSecondary)
                    }
                    Spacer()
                    metric("mappin.and.ellipse", "\(route.stops.count)")
                    Spacer()
                    metric("heart.fill", "\(Int(route.welfare))%")
                }
            }
        }
    }

    private func metric(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundColor(NRColor.accent)
            Text(text).font(NRFont.callout).foregroundColor(NRColor.textSecondary)
        }
    }
}
