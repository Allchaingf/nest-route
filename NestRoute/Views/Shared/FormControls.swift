//
//  FormControls.swift
//  NestRoute
//
//  Shared building blocks for the data-entry forms: a sheet scaffold with a
//  pinned save button, a horizontally scrolling chip selector, and a field
//  label wrapper. Keeps every form visually consistent.
//

import SwiftUI

// MARK: - Form scaffold (sheet)

struct FormScaffold<Content: View>: View {
    let title: String
    var saveTitle: String = "Save"
    let canSave: Bool
    let onSave: () -> Void
    let content: Content

    @Environment(\.presentationMode) private var presentation

    init(title: String, saveTitle: String = "Save", canSave: Bool,
         onSave: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.saveTitle = saveTitle
        self.canSave = canSave
        self.onSave = onSave
        self.content = content()
    }

    var body: some View {
        ZStack {
            NRBackground()
            VStack(spacing: 0) {
                // header
                HStack {
                    Text(title).font(NRFont.title).foregroundColor(NRColor.textPrimary)
                    Spacer()
                    Button {
                        Haptics.tap()
                        presentation.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(NRColor.textMuted)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(NRColor.surface))
                            .overlay(Circle().stroke(NRColor.hairline, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: NRSpacing.md) {
                        content
                        Color.clear.frame(height: 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                }

                // pinned save
                PrimaryButton(title: saveTitle, icon: "checkmark") {
                    guard canSave else { return }
                    onSave()
                    Haptics.success()
                    presentation.wrappedValue.dismiss()
                }
                .opacity(canSave ? 1 : 0.5)
                .disabled(!canSave)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(NRColor.bgBottom.opacity(0.001))
            }
        }
    }
}

// MARK: - Chip selector

struct ChipSelector<Item: Identifiable>: View {
    let label: String
    let items: [Item]
    let isSelected: (Item) -> Bool
    let title: (Item) -> String
    var icon: (Item) -> String? = { _ in nil }
    let onTap: (Item) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(NRFont.caption).foregroundColor(NRColor.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        Button {
                            Haptics.tap()
                            onTap(item)
                        } label: {
                            TagPill(text: title(item), icon: icon(item), selected: isSelected(item))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Stepper field

struct NRStepperField: View {
    let title: String
    var unit: String = ""
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...100000
    var step: Int = 1

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(NRFont.caption).foregroundColor(NRColor.textMuted)
                Text("\(value) \(unit)").font(NRFont.headline).foregroundColor(NRColor.textPrimary)
            }
            Spacer()
            HStack(spacing: 14) {
                stepButton("minus") { value = max(range.lowerBound, value - step) }
                stepButton("plus") { value = min(range.upperBound, value + step) }
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
