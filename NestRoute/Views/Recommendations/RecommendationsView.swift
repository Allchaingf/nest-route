//
//  RecommendationsView.swift
//  NestRoute
//
//  Recommendations section (Экран 12 — Tips & actions). Surfaces data-driven
//  warnings that need attention and general best-practice advice.
//

import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject private var store: DataStore

    private var warnings: [Recommendation] { store.warnings }
    private var tips: [Recommendation] { store.recommendations.filter { $0.severity == .nominal } }

    var body: some View {
        ZStack {
            NRBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: NRSpacing.lg) {
                    NRHeaderBar(title: "Recommendations", subtitle: "Keep every transport safe", showBack: true)

                    summaryCard

                    if !warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Needs attention")
                            ForEach(warnings) { rec in RecommendationCard(rec: rec) }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Best practices")
                        ForEach(tips) { rec in RecommendationCard(rec: rec) }
                    }

                    TabBarSpacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
    }

    private var summaryCard: some View {
        NRCard {
            HStack(spacing: 18) {
                RingProgress(value: store.averageWelfare / 100, size: 96, lineWidth: 12,
                             tint: store.averageWelfare < 70 ? NRColor.warn : NRColor.accent,
                             label: "\(Int(store.averageWelfare))%", caption: "avg")
                VStack(alignment: .leading, spacing: 6) {
                    Text(warnings.isEmpty ? "Everything looks good" : "\(warnings.count) item(s) to review")
                        .font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Text(warnings.isEmpty
                         ? "No active warnings. Keep logging welfare to maintain the score."
                         : "Address the warnings below to protect bird welfare.")
                        .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct RecommendationCard: View {
    let rec: Recommendation
    var body: some View {
        NRCard {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(rec.color.opacity(0.16)).frame(width: 46, height: 46)
                    Image(systemName: rec.icon).font(.system(size: 20)).foregroundColor(rec.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(rec.title).font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    Text(rec.detail).font(NRFont.callout).foregroundColor(NRColor.textMuted)
                }
                Spacer(minLength: 0)
            }
        }
    }
}
