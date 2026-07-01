//
//  GroupDetailView.swift
//  NestRoute
//
//  Detail card for a single bird group: stats, notes and the routes that
//  carry it. Edit / delete fully wired.
//

import SwiftUI

struct GroupDetailView: View {
    let groupId: UUID
    @EnvironmentObject private var store: DataStore
    @Environment(\.presentationMode) private var presentation
    @State private var showEdit = false

    private var group: BirdGroup? { store.groups.first { $0.id == groupId } }
    private var routes: [TransportRoute] { store.routes.filter { $0.groupIds.contains(groupId) } }

    var body: some View {
        ZStack {
            NRBackground()
            if let group = group {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: NRSpacing.lg) {
                        NRHeaderBar(title: "Group", subtitle: group.name, showBack: true,
                                    trailingIcon: "square.and.pencil", trailingAction: { showEdit = true })

                        NRCard {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle().fill(group.category.color.opacity(0.16)).frame(width: 86, height: 86)
                                    Image(systemName: group.category.icon)
                                        .font(.system(size: 38)).foregroundColor(group.category.color)
                                }
                                Text(group.name).font(NRFont.title).foregroundColor(NRColor.textPrimary)
                                HStack {
                                    detailStat("\(group.count)", "Birds", NRColor.accent)
                                    Divider().frame(height: 36).background(NRColor.hairline)
                                    detailStat(group.category.title, "Category", group.category.color)
                                    Divider().frame(height: 36).background(NRColor.hairline)
                                    detailStat("\(routes.count)", "Routes", NRColor.blue)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        if !group.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Notes")
                                NRCard {
                                    Text(group.notes).font(NRFont.body).foregroundColor(NRColor.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "On routes")
                            if routes.isEmpty {
                                NRCard { Text("Not assigned to any route yet.")
                                    .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading) }
                            } else {
                                ForEach(routes) { route in
                                    NavigationLink(destination: RoutePlannerView(routeId: route.id)) {
                                        RouteCard(route: route, birds: store.birds(in: route))
                                    }.buttonStyle(PlainButtonStyle())
                                }
                            }
                        }

                        Button {
                            Haptics.tap(.medium)
                            store.deleteGroup(group)
                            presentation.wrappedValue.dismiss()
                        } label: {
                            HStack { Image(systemName: "trash"); Text("Delete group") }
                                .font(NRFont.headline).foregroundColor(NRColor.danger)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous).fill(NRColor.danger.opacity(0.12)))
                        }
                        .buttonStyle(PlainButtonStyle())

                        TabBarSpacer()
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                EmptyStateView(icon: "leaf.fill", title: "Not found", message: "This group was removed.",
                               customIcon: AnyView(BirdGlyph(size: 40, color: NRColor.accent)))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEdit) { if let group = group { AddGroupView(group: group) } }
    }

    private func detailStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundColor(color)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(NRFont.caption).foregroundColor(NRColor.textMuted)
        }.frame(maxWidth: .infinity)
    }
}
