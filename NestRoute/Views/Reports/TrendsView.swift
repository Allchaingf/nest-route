//
//  TrendsView.swift
//  NestRoute
//
//  Trends section (Экран 16 — Graphs & changes). Works globally or for a
//  single route, showing welfare / movement charts and change indicators.
//

import SwiftUI

struct TrendsView: View {
    var routeId: UUID? = nil
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var settings: AppSettings

    private var route: TransportRoute? { routeId.flatMap { id in store.routes.first { $0.id == id } } }

    private var welfarePoints: [ChartPoint] {
        if let route = route, route.records.count >= 2 {
            return route.records.sorted { $0.date < $1.date }.map {
                ChartPoint(label: NRFormat.time.string(from: $0.date), value: $0.value)
            }
        }
        return store.welfareTrend
    }

    private var welfareDelta: Double {
        let v = welfarePoints.map { $0.value }
        guard let first = v.first, let last = v.last else { return 0 }
        return last - first
    }

    var body: some View {
        ZStack {
            NRBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: NRSpacing.lg) {
                    NRHeaderBar(title: "Trends",
                                subtitle: route?.name ?? "All routes",
                                showBack: true)

                    changeCards

                    chartCard(title: "Welfare over time", icon: "waveform.path.ecg") {
                        LineChartView(points: welfarePoints, tint: NRColor.accent, height: 170)
                    }

                    chartCard(title: "Movement", icon: "chart.bar.fill") {
                        BarChartView(points: store.weeklyMovement, tint: NRColor.blue, height: 150)
                    }

                    if let route = route, !route.stops.isEmpty {
                        chartCard(title: "Stop durations", icon: "timer") {
                            BarChartView(points: route.stops.map { ChartPoint(label: $0.type.title, value: Double($0.durationMin)) },
                                         tint: NRColor.gold, height: 140)
                        }
                    }

                    TabBarSpacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
    }

    private var changeCards: some View {
        HStack(spacing: 14) {
            ChangeCard(title: "Welfare", value: "\(Int(welfarePoints.last?.value ?? 0))%",
                       delta: welfareDelta, unit: "%", tint: NRColor.accent)
            ChangeCard(title: route == nil ? "Avg welfare" : "Records",
                       value: route == nil ? "\(Int(store.averageWelfare))%" : "\(route?.records.count ?? 0)",
                       delta: route == nil ? welfareDelta : 0, unit: "", tint: NRColor.blue)
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

struct ChangeCard: View {
    let title: String
    let value: String
    let delta: Double
    let unit: String
    let tint: Color

    private var up: Bool { delta >= 0 }

    var body: some View {
        NRCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(NRFont.caption).foregroundColor(NRColor.textMuted)
                Text(value).font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundColor(NRColor.textPrimary)
                if delta != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .bold))
                        Text("\(up ? "+" : "")\(Int(delta))\(unit)").font(NRFont.caption)
                    }
                    .foregroundColor(up ? NRColor.ok : NRColor.danger)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill((up ? NRColor.ok : NRColor.danger).opacity(0.15)))
                } else {
                    Text("No change").font(NRFont.caption).foregroundColor(NRColor.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
