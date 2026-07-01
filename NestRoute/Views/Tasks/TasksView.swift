//
//  TasksView.swift
//  NestRoute
//
//  Tasks section (Экран 13): open & completed tasks with toggle, filter,
//  add / delete. Tasks can be linked to a route.
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showAdd = false
    @State private var showDone = false

    private var open: [TaskItem] { store.tasks.filter { !$0.isDone }.sorted { $0.due < $1.due } }
    private var done: [TaskItem] { store.tasks.filter { $0.isDone }.sorted { $0.due > $1.due } }

    var body: some View {
        ZStack {
            NRBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: NRSpacing.md) {
                    NRHeaderBar(title: "Tasks",
                                subtitle: "\(open.count) open · \(done.count) done",
                                showBack: true,
                                trailingIcon: "plus", trailingAction: { showAdd = true })

                    if store.tasks.isEmpty {
                        EmptyStateView(icon: "checkmark.circle",
                                       title: "No tasks",
                                       message: "Add a task to stay on top of your transport checklist.",
                                       actionTitle: "Add task") { showAdd = true }
                    } else {
                        if !open.isEmpty {
                            SectionHeader(title: "Open")
                            ForEach(open) { task in taskRow(task) }
                        }
                        if !done.isEmpty {
                            HStack {
                                Text("Completed").font(NRFont.title2).foregroundColor(NRColor.textPrimary)
                                Spacer()
                                Button { withAnimation { showDone.toggle() } } label: {
                                    Image(systemName: showDone ? "chevron.up" : "chevron.down")
                                        .foregroundColor(NRColor.textMuted)
                                }
                            }
                            if showDone {
                                ForEach(done) { task in taskRow(task) }
                            }
                        }
                    }
                    TabBarSpacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAdd) { AddTaskView() }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        TaskRow(task: task) { store.toggleTask(task) }
            .contextMenu {
                Button { store.deleteTask(task) } label: { Label("Delete", systemImage: "trash") }
            }
    }
}

struct AddTaskView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = AddTaskViewModel()

    var body: some View {
        FormScaffold(title: "New task", canSave: vm.isValid, onSave: { store.addTask(vm.build()) }) {
            NRTextField(title: "Title", icon: "checkmark.circle.fill", placeholder: "e.g. Confirm permits", text: $vm.title)
            NRTextEditor(title: "Details", text: $vm.detail)

            VStack(alignment: .leading, spacing: 6) {
                Text("Due").font(NRFont.caption).foregroundColor(NRColor.textMuted)
                DatePicker("", selection: $vm.due)
                    .labelsHidden().datePickerStyle(CompactDatePickerStyle()).accentColor(NRColor.accent)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).fill(NRColor.surfaceAlt))
                    .overlay(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).stroke(NRColor.hairline, lineWidth: 1))
            }

            ChipSelector(label: "Priority", items: TaskPriority.allCases,
                         isSelected: { $0 == vm.priority }, title: { $0.title }, icon: { $0.icon },
                         onTap: { vm.priority = $0 })

            if !store.routes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Link to route (optional)").font(NRFont.caption).foregroundColor(NRColor.textMuted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Button { Haptics.tap(); vm.routeId = nil } label: {
                                TagPill(text: "None", selected: vm.routeId == nil)
                            }.buttonStyle(PlainButtonStyle())
                            ForEach(store.routes) { route in
                                Button { Haptics.tap(); vm.routeId = route.id } label: {
                                    TagPill(text: route.name, icon: route.status.icon, selected: vm.routeId == route.id)
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
        }
    }
}
