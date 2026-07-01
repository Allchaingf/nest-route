//
//  GroupsListView.swift
//  NestRoute
//
//  Bird Groups section (Экран 7): the catalogue of bird groups with category
//  filtering, add / edit / delete and a link to each group's detail.
//

import SwiftUI

struct GroupsListView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showAdd = false
    @State private var editing: BirdGroup?
    @State private var filter: BirdCategory?

    private var filtered: [BirdGroup] {
        guard let f = filter else { return store.groups }
        return store.groups.filter { $0.category == f }
    }

    var body: some View {
        NavigationView {
            ZStack {
                NRBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: NRSpacing.md) {
                        NRHeaderBar(title: "Bird Groups",
                                    subtitle: "\(store.groups.count) groups · \(store.totalBirds) birds",
                                    trailingIcon: "plus", trailingAction: { showAdd = true })

                        summaryCard
                        filterBar

                        if filtered.isEmpty {
                            EmptyStateView(icon: "leaf.fill",
                                           title: "No groups",
                                           message: "Add a bird group to begin planning its transport.",
                                           actionTitle: "Add group", action: { showAdd = true },
                                           customIcon: AnyView(BirdGlyph(size: 40, color: NRColor.accent)))
                        } else {
                            ForEach(filtered) { group in
                                NavigationLink(destination: GroupDetailView(groupId: group.id)) {
                                    GroupRow(group: group)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button { editing = group } label: { Label("Edit", systemImage: "pencil") }
                                    Button { store.deleteGroup(group) } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                        }
                        TabBarSpacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddGroupView() }
            .sheet(item: $editing) { group in AddGroupView(group: group) }
        }
        .nrStackNavigation()
    }

    private var summaryCard: some View {
        NRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Flock distribution").font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Spacer()
                    Text("\(store.totalBirds) total").font(NRFont.caption).foregroundColor(NRColor.textMuted)
                }
                if store.categoryDistribution.isEmpty {
                    Text("Add groups to see the distribution.")
                        .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                } else {
                    DistributionBar(segments: store.categoryDistribution)
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button { Haptics.tap(); filter = nil } label: {
                    TagPill(text: "All", icon: "square.grid.2x2", selected: filter == nil)
                }.buttonStyle(PlainButtonStyle())
                ForEach(BirdCategory.allCases) { cat in
                    Button { Haptics.tap(); filter = (filter == cat ? nil : cat) } label: {
                        TagPill(text: cat.title, icon: cat.icon, selected: filter == cat)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
