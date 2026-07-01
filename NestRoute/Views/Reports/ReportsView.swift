//
//  ReportsView.swift
//  NestRoute
//
//  Reports section (Экран 15 — Analytics): summary stats and a set of charts
//  built from live data — weekly movement, welfare trend, category split and
//  route-status breakdown.
//

import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var settings: AppSettings

    private var totalDistance: Double { store.routes.map { $0.distanceKm }.reduce(0, +) }
    private var statusCounts: [(RouteStatus, Int)] {
        RouteStatus.allCases.map { status in (status, store.routes.filter { $0.status == status }.count) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                NRBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: NRSpacing.lg) {
                        NRHeaderBar(title: "Reports", subtitle: "Transport analytics")

                        summaryGrid

                        chartCard(title: "Bird movement this week", icon: "chart.bar.fill") {
                            BarChartView(points: store.weeklyMovement, tint: NRColor.accent, height: 150)
                        }

                        chartCard(title: "Welfare trend", icon: "waveform.path.ecg") {
                            LineChartView(points: store.welfareTrend, tint: NRColor.blue, height: 160)
                        }

                        chartCard(title: "Flock by category", icon: "chart.pie.fill") {
                            if store.categoryDistribution.isEmpty {
                                Text("No data yet.").font(NRFont.callout).foregroundColor(NRColor.textMuted)
                            } else {
                                DistributionBar(segments: store.categoryDistribution)
                            }
                        }

                        statusBreakdown

                        NavigationLink(destination: TrendsView()) {
                            ActionLinkRow(icon: "chart.bar.xaxis", title: "Open detailed trends", tint: NRColor.accent)
                        }.buttonStyle(PlainButtonStyle())

                        TabBarSpacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .nrStackNavigation()
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            StatTile(icon: "map.fill", tint: NRColor.accent, value: "\(store.routes.count)", label: "Total routes")
            StatTile(icon: "checkmark.seal.fill", tint: NRColor.accentDeep, value: "\(store.completedRoutesCount)", label: "Completed")
            StatTile(icon: "arrow.left.and.right", tint: NRColor.blue, value: settings.formattedDistance(totalDistance), label: "Total distance")
            StatTile(icon: "heart.fill", tint: NRColor.danger, value: "\(Int(store.averageWelfare))%", label: "Avg welfare")
        }
    }

    private var statusBreakdown: some View {
        NRCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "list.bullet").foregroundColor(NRColor.accent)
                    Text("Routes by status").font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                }
                let maxCount = max(statusCounts.map { $0.1 }.max() ?? 1, 1)
                ForEach(statusCounts, id: \.0) { status, count in
                    HStack(spacing: 10) {
                        Image(systemName: status.icon).font(.system(size: 13)).foregroundColor(status.color).frame(width: 22)
                        Text(status.title).font(NRFont.callout).foregroundColor(NRColor.textSecondary).frame(width: 84, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(NRColor.hairline).frame(height: 8)
                                Capsule().fill(status.color)
                                    .frame(width: max(geo.size.width * CGFloat(count) / CGFloat(maxCount), count == 0 ? 0 : 8), height: 8)
                            }
                        }.frame(height: 8)
                        Text("\(count)").font(NRFont.callout).foregroundColor(NRColor.textPrimary).frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func chartCard<C: View>(title: String, icon: String, @ViewBuilder content: () -> C) -> some View {
        NRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon).foregroundColor(NRColor.accent)
                    Text(title).font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Spacer()
                }
                content()
            }
        }
    }
}
