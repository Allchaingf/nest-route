//
//  StopsListView.swift
//  NestRoute
//
//  Stops section: every rest, feeding, watering and checkpoint stop across
//  all routes, filterable by type. Add / delete fully wired.
//

import SwiftUI

struct StopsListView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showAdd = false
    @State private var filter: StopType?

    private var stops: [DataStore.StopRef] {
        let all = store.allStops
        guard let f = filter else { return all }
        return all.filter { $0.stop.type == f }
    }

    var body: some View {
        NavigationView {
            ZStack {
                NRBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: NRSpacing.md) {
                        NRHeaderBar(title: "Stops",
                                    subtitle: "\(store.allStops.count) stops across \(store.routes.count) routes",
                                    trailingIcon: "plus", trailingAction: { showAdd = true })

                        typeFilter

                        if stops.isEmpty {
                            EmptyStateView(icon: "mappin.slash",
                                           title: "No stops",
                                           message: "Add rest and watering stops to keep birds comfortable on long trips.",
                                           actionTitle: "Add stop") { showAdd = true }
                        } else {
                            ForEach(stops) { ref in
                                NavigationLink(destination: RoutePlannerView(routeId: ref.route.id)) {
                                    StopRefRow(ref: ref)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button { store.deleteStop(ref.stop.id, from: ref.route.id) } label: {
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
            .sheet(isPresented: $showAdd) { AddStopView() }
        }
        .nrStackNavigation()
    }

    private var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button { Haptics.tap(); filter = nil } label: {
                    TagPill(text: "All", icon: "square.grid.2x2", selected: filter == nil)
                }.buttonStyle(PlainButtonStyle())
                ForEach(StopType.allCases) { type in
                    Button { Haptics.tap(); filter = (filter == type ? nil : type) } label: {
                        TagPill(text: type.title, icon: type.icon, selected: filter == type)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct StopRefRow: View {
    let ref: DataStore.StopRef
    var body: some View {
        NRCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(ref.stop.type.color.opacity(0.16)).frame(width: 44, height: 44)
                    Image(systemName: ref.stop.type.icon).foregroundColor(ref.stop.type.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(ref.stop.name).font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Text("\(ref.stop.type.title) · \(ref.stop.durationMin) min")
                        .font(NRFont.caption).foregroundColor(NRColor.textMuted)
                    HStack(spacing: 4) {
                        Image(systemName: "map.fill").font(.system(size: 9)).foregroundColor(NRColor.accent)
                        Text(ref.route.name).font(NRFont.caption).foregroundColor(NRColor.accentDeep)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(NRColor.textMuted)
            }
        }
    }
}
