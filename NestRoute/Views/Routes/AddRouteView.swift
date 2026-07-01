//
//  AddRouteView.swift
//  NestRoute
//
//  Add / edit a transport route: name, origin, destination, distance,
//  departure, status, attached bird groups and notes.
//

import SwiftUI

struct AddRouteView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var vm: AddRouteViewModel

    init(route: TransportRoute? = nil) {
        _vm = StateObject(wrappedValue: AddRouteViewModel(route: route))
    }

    var body: some View {
        FormScaffold(title: vm.editing == nil ? "New route" : "Edit route",
                     canSave: vm.isValid,
                     onSave: save) {

            NRTextField(title: "Route name", icon: "map.fill", placeholder: "e.g. Valley Relocation", text: $vm.name)
            NRTextField(title: "Origin", icon: "location.circle.fill", placeholder: "From", text: $vm.origin)
            NRTextField(title: "Destination", icon: "mappin.circle.fill", placeholder: "To", text: $vm.destination)
            NRTextField(title: "Distance (km)", icon: "ruler", placeholder: "0",
                        text: $vm.distanceText, keyboard: .numberPad)

            // Departure
            VStack(alignment: .leading, spacing: 6) {
                Text("Departure").font(NRFont.caption).foregroundColor(NRColor.textMuted)
                DatePicker("", selection: $vm.departure)
                    .labelsHidden()
                    .datePickerStyle(CompactDatePickerStyle())
                    .accentColor(NRColor.accent)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).fill(NRColor.surfaceAlt))
                    .overlay(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).stroke(NRColor.hairline, lineWidth: 1))
            }

            ChipSelector(label: "Status",
                         items: RouteStatus.allCases,
                         isSelected: { $0 == vm.status },
                         title: { $0.title },
                         icon: { $0.icon },
                         onTap: { vm.status = $0 })

            // Group multi-select
            VStack(alignment: .leading, spacing: 8) {
                Text("Bird groups").font(NRFont.caption).foregroundColor(NRColor.textMuted)
                if store.groups.isEmpty {
                    Text("No groups yet — add one first to attach it.")
                        .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(store.groups) { group in
                                Button {
                                    Haptics.tap()
                                    if vm.selectedGroupIds.contains(group.id) { vm.selectedGroupIds.remove(group.id) }
                                    else { vm.selectedGroupIds.insert(group.id) }
                                } label: {
                                    TagPill(text: "\(group.name) (\(group.count))",
                                            icon: group.category.icon,
                                            selected: vm.selectedGroupIds.contains(group.id))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }

            NRTextEditor(title: "Notes", text: $vm.notes)
        }
    }

    private func save() {
        let route = vm.build()
        if vm.editing == nil { store.addRoute(route) } else { store.updateRoute(route) }
    }
}
