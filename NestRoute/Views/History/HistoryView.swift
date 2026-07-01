//
//  HistoryView.swift
//  NestRoute
//
//  History section (Экран 17): a chronological timeline of welfare records,
//  completed routes and finished tasks.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: DataStore

    private var entries: [HistoryEntry] { store.historyEntries }

    var body: some View {
        ZStack {
            NRBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: NRSpacing.md) {
                    NRHeaderBar(title: "History", subtitle: "\(entries.count) recorded events", showBack: true)

                    if entries.isEmpty {
                        EmptyStateView(icon: "clock.arrow.circlepath",
                                       title: "Nothing yet",
                                       message: "Welfare records and completed trips will appear here.")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                TimelineRow(entry: entry, isLast: index == entries.count - 1)
                            }
                        }
                    }
                    TabBarSpacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
    }
}

struct TimelineRow: View {
    let entry: HistoryEntry
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(entry.color.opacity(0.16)).frame(width: 38, height: 38)
                    Image(systemName: entry.icon).font(.system(size: 15)).foregroundColor(entry.color)
                }
                if !isLast {
                    Rectangle().fill(NRColor.hairline).frame(width: 2).frame(maxHeight: .infinity)
                }
            }
            .frame(width: 38)

            NRCard(padding: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title).font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                    if !entry.subtitle.isEmpty {
                        Text(entry.subtitle).font(NRFont.caption).foregroundColor(NRColor.textMuted)
                    }
                    Text(NRFormat.dateTime(entry.date)).font(NRFont.tiny).foregroundColor(NRColor.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 14)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
