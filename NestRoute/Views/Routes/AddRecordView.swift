//
//  AddRecordView.swift
//  NestRoute
//
//  Add a welfare record to a route (Экран 11 — Add Record): Date, Status, Value.
//

import SwiftUI

struct AddRecordView: View {
    let routeId: UUID
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = AddRecordViewModel()

    var body: some View {
        FormScaffold(title: "Add record", canSave: vm.isValid, onSave: save) {

            // Date
            VStack(alignment: .leading, spacing: 6) {
                Text("Date & time").font(NRFont.caption).foregroundColor(NRColor.textMuted)
                DatePicker("", selection: $vm.date)
                    .labelsHidden()
                    .datePickerStyle(CompactDatePickerStyle())
                    .accentColor(NRColor.accent)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).fill(NRColor.surfaceAlt))
                    .overlay(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).stroke(NRColor.hairline, lineWidth: 1))
            }

            ChipSelector(label: "Status",
                         items: RecordStatus.allCases,
                         isSelected: { $0 == vm.status },
                         title: { $0.title },
                         icon: { $0.icon },
                         onTap: { vm.status = $0 })

            // Value slider
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Welfare index").font(NRFont.caption).foregroundColor(NRColor.textMuted)
                    Spacer()
                    Text("\(Int(vm.value))%")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(vm.status.color)
                }
                Slider(value: $vm.value, in: 0...100, step: 1)
                    .accentColor(vm.status.color)
                RingProgress(value: vm.value / 100, size: 96, lineWidth: 12,
                             tint: vm.status.color, label: "\(Int(vm.value))", caption: "index")
                    .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous).fill(NRColor.surface))
            .overlay(RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous).stroke(NRColor.hairline, lineWidth: 1))

            NRTextEditor(title: "Note", text: $vm.note)
        }
    }

    private func save() {
        store.addRecord(vm.build(), to: routeId)
    }
}
