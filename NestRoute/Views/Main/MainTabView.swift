//
//  MainTabView.swift
//  NestRoute
//
//  The main app shell: five primary sections behind a custom floating
//  tab bar — Dashboard, Routes, Bird Groups, Stops, Reports.
//

import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case dashboard, routes, groups, stops, reports
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .routes:    return "Routes"
        case .groups:    return "Groups"
        case .stops:     return "Stops"
        case .reports:   return "Reports"
        }
    }
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .routes:    return "map.fill"
        case .groups:    return "leaf.fill"
        case .stops:     return "mappin.and.ellipse"
        case .reports:   return "chart.bar.fill"
        }
    }
}

struct MainTabView: View {
    @State private var tab: AppTab = .dashboard
    @Namespace private var ns

    var body: some View {
        ZStack(alignment: .bottom) {
            NRBackground()

            Group {
                switch tab {
                case .dashboard: DashboardView(selectTab: { tab = $0 })
                case .routes:    RoutesListView()
                case .groups:    GroupsListView()
                case .stops:     StopsListView()
                case .reports:   ReportsView()
                }
            }

            CustomTabBar(selection: $tab, ns: ns)
        }
    }
}

// MARK: - Custom tab bar

struct CustomTabBar: View {
    @Binding var selection: AppTab
    var ns: Namespace.ID

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { item in
                let isSelected = item == selection
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { selection = item }
                } label: {
                    HStack(spacing: 6) {
                        if item == .groups {
                            BirdGlyph(size: 18, color: isSelected ? NRColor.onAccent : NRColor.textMuted)
                        } else {
                            Image(systemName: item.icon)
                                .font(.system(size: 17, weight: .semibold))
                        }
                        if isSelected {
                            Text(item.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .lineLimit(1)
                        }
                    }
                    .foregroundColor(isSelected ? NRColor.onAccent : NRColor.textMuted)
                    .padding(.vertical, 10)
                    .padding(.horizontal, isSelected ? 14 : 10)
                    .background(
                        ZStack {
                            if isSelected {
                                Capsule()
                                    .fill(NRGradient.brand)
                                    .matchedGeometryEffect(id: "tabPill", in: ns)
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(NRColor.surface)
                .overlay(Capsule().stroke(NRColor.hairline, lineWidth: 1))
        )
        .nrSoftShadow()
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}
