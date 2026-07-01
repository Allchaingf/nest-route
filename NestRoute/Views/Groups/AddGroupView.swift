//
//  AddGroupView.swift
//  NestRoute
//
//  Add / edit a bird group (Экран 8 — Add New): Name, Category, Count, Notes.
//

import SwiftUI

struct AddGroupView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm: AddGroupViewModel

    init(group: BirdGroup? = nil) {
        _vm = StateObject(wrappedValue: AddGroupViewModel(group: group))
    }

    var body: some View {
        FormScaffold(title: vm.editing == nil ? "New group" : "Edit group",
                     canSave: vm.isValid,
                     onSave: save) {

            NRTextField(title: "Name", icon: "tag.fill", placeholder: "e.g. Highland Layers", text: $vm.name)

            ChipSelector(label: "Category",
                         items: BirdCategory.allCases,
                         isSelected: { $0 == vm.category },
                         title: { $0.title },
                         icon: { $0.icon },
                         onTap: { vm.category = $0 })

            NRTextField(title: "Number of birds", icon: "number", placeholder: "0",
                        text: $vm.countText, keyboard: .numberPad)

            NRTextEditor(title: "Notes", text: $vm.notes)

            // Live preview card
            NRCard {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(vm.category.color.opacity(0.16)).frame(width: 46, height: 46)
                        Image(systemName: vm.category.icon).foregroundColor(vm.category.color)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(vm.name.isEmpty ? "Group name" : vm.name)
                            .font(NRFont.headline).foregroundColor(NRColor.textPrimary)
                        Text("\(vm.category.title) · \(vm.count) birds")
                            .font(NRFont.caption).foregroundColor(NRColor.textMuted)
                    }
                    Spacer()
                }
            }
        }
    }

    private func save() {
        let group = vm.build()
        if vm.editing == nil { store.addGroup(group) } else { store.updateGroup(group) }
    }
}
