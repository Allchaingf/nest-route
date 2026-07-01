//
//  AddStopView.swift
//  NestRoute
//
//  Add a stop to a route: name, type, duration and which route it belongs to.
//

import SwiftUI

struct AddStopView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm: AddStopViewModel

    init(defaultRouteId: UUID? = nil) {
        _vm = StateObject(wrappedValue: AddStopViewModel(defaultRouteId: defaultRouteId))
    }

    var body: some View {
        FormScaffold(title: "New stop", canSave: vm.isValid, onSave: save) {

            NRTextField(title: "Stop name", icon: "mappin.and.ellipse", placeholder: "e.g. Brook Watering", text: $vm.name)

            ChipSelector(label: "Type",
                         items: StopType.allCases,
                         isSelected: { $0 == vm.type },
                         title: { $0.title },
                         icon: { $0.icon },
                         onTap: { vm.type = $0 })

            // Duration stepper
            NRStepperFieldBinding(title: "Duration", unit: "min", text: $vm.durationText, step: 5)

            // Route selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Route").font(NRFont.caption).foregroundColor(NRColor.textMuted)
                if store.routes.isEmpty {
                    Text("No routes yet — create a route first.")
                        .font(NRFont.callout).foregroundColor(NRColor.textMuted)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(store.routes) { route in
                                Button {
                                    Haptics.tap(); vm.routeId = route.id
                                } label: {
                                    TagPill(text: route.name, icon: route.status.icon,
                                            selected: vm.routeId == route.id)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }

            NRTextEditor(title: "Note", text: $vm.note)
        }
    }

    private func save() {
        guard let routeId = vm.routeId else { return }
        store.addStop(vm.build(), to: routeId)
    }
}

/// Stepper that edits a numeric text binding (keeps VM fields as text).
struct NRStepperFieldBinding: View {
    let title: String
    var unit: String = ""
    @Binding var text: String
    var step: Int = 1

    private var value: Int { Int(text) ?? 0 }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(NRFont.caption).foregroundColor(NRColor.textMuted)
                Text("\(value) \(unit)").font(NRFont.headline).foregroundColor(NRColor.textPrimary)
            }
            Spacer()
            HStack(spacing: 14) {
                stepButton("minus") { text = "\(max(0, value - step))" }
                stepButton("plus") { text = "\(value + step)" }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).fill(NRColor.surfaceAlt))
        .overlay(RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous).stroke(NRColor.hairline, lineWidth: 1))
    }

    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); action() } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(NRColor.accentDeep)
                .frame(width: 34, height: 34)
                .background(Circle().fill(NRColor.surface))
                .overlay(Circle().stroke(NRColor.hairline, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
