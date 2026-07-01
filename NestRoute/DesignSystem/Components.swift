//
//  Components.swift
//  NestRoute
//
//  Reusable, custom-styled component library. Nothing here uses default
//  SwiftUI plain styling — buttons, cards, fields and badges are all bespoke.
//

import SwiftUI

// MARK: - Screen background

struct NRBackground: View {
    var body: some View {
        NRGradient.appBackground
            .ignoresSafeArea()
    }
}

/// Wraps content in the standard app background.
struct NRScreen<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ZStack {
            NRBackground()
            content
        }
    }
}

// MARK: - Card

struct NRCard<Content: View>: View {
    var padding: CGFloat = NRSpacing.md
    let content: Content
    init(padding: CGFloat = NRSpacing.md, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous)
                    .fill(NRColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous)
                    .stroke(NRColor.hairline, lineWidth: 1)
            )
            .nrTightShadow()
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            Haptics.tap(.medium)
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon) }
                Text(title)
            }
            .font(NRFont.headline)
            .foregroundColor(NRColor.onAccent)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 15)
            .padding(.horizontal, fullWidth ? 0 : 26)
            .background(
                RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous)
                    .fill(NRGradient.brand)
            )
            .shadow(color: NRColor.accent.opacity(0.35), radius: 12, x: 0, y: 6)
            .scaleEffect(pressed ? 0.96 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false } }
        )
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap(.light)
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon) }
                Text(title)
            }
            .font(NRFont.headline)
            .foregroundColor(NRColor.accentDeep)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 15)
            .padding(.horizontal, fullWidth ? 0 : 26)
            .background(
                RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous)
                    .fill(NRColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NRRadius.md, style: .continuous)
                    .stroke(NRColor.accent.opacity(0.5), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Small circular icon button used in toolbars / headers.
struct CircleIconButton: View {
    let icon: String
    var tint: Color = NRColor.accentDeep
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 40, height: 40)
                .background(Circle().fill(NRColor.surface))
                .overlay(Circle().stroke(NRColor.hairline, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Text field

struct NRTextField: View {
    let title: String
    var icon: String? = nil
    var placeholder: String = ""
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(NRFont.caption)
                .foregroundColor(NRColor.textMuted)
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(NRColor.accent)
                        .frame(width: 18)
                }
                TextField(placeholder, text: $text)
                    .font(NRFont.body)
                    .foregroundColor(NRColor.textPrimary)
                    .keyboardType(keyboard)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous)
                    .fill(NRColor.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous)
                    .stroke(NRColor.hairline, lineWidth: 1)
            )
        }
    }
}

struct NRTextEditor: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(NRFont.caption)
                .foregroundColor(NRColor.textMuted)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Add a note…")
                        .font(NRFont.body)
                        .foregroundColor(NRColor.textMuted.opacity(0.7))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                }
                TextEditor(text: $text)
                    .font(NRFont.body)
                    .foregroundColor(NRColor.textPrimary)
                    .frame(height: 96)
                    .padding(8)
                    .opacity(text.isEmpty ? 0.85 : 1)
            }
            .background(
                RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous)
                    .fill(NRColor.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NRRadius.sm, style: .continuous)
                    .stroke(NRColor.hairline, lineWidth: 1)
            )
        }
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text(title)
                .font(NRFont.title2)
                .foregroundColor(NRColor.textPrimary)
            Spacer()
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(NRFont.callout)
                        .foregroundColor(NRColor.accentDeep)
                }
            }
        }
    }
}

// MARK: - Status badge

struct StatusBadge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(NRFont.tiny)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.16)))
    }
}

/// Rounded tag pill (selectable).
struct TagPill: View {
    let text: String
    var icon: String? = nil
    var selected: Bool = false
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon { Image(systemName: icon).font(.system(size: 11, weight: .bold)) }
            Text(text).font(NRFont.caption)
        }
        .foregroundColor(selected ? NRColor.onAccent : NRColor.textSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(pillBackground)
    }

    @ViewBuilder private var pillBackground: some View {
        if selected {
            Capsule().fill(NRGradient.brand)
        } else {
            Capsule()
                .fill(NRColor.surfaceAlt)
                .overlay(Capsule().stroke(NRColor.hairline, lineWidth: 1))
        }
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var customIcon: AnyView? = nil

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(NRColor.accent.opacity(0.12))
                    .frame(width: 96, height: 96)
                if let customIcon = customIcon {
                    customIcon
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(NRColor.accent)
                }
            }
            Text(title)
                .font(NRFont.title2)
                .foregroundColor(NRColor.textPrimary)
            Text(message)
                .font(NRFont.body)
                .foregroundColor(NRColor.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, icon: "plus", fullWidth: false, action: action)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Labeled info row

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var tint: Color = NRColor.accent
    var customIcon: AnyView? = nil
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let customIcon = customIcon {
                    customIcon
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(tint)
                }
            }
            .frame(width: 30, height: 30)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(tint.opacity(0.14)))
            Text(label)
                .font(NRFont.callout)
                .foregroundColor(NRColor.textMuted)
            Spacer()
            Text(value)
                .font(NRFont.headline)
                .foregroundColor(NRColor.textPrimary)
        }
    }
}

// MARK: - Toast / confirmation

struct ConfirmationToast: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(NRColor.onAccent)
            Text(text)
                .font(NRFont.callout)
                .foregroundColor(NRColor.onAccent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(Capsule().fill(NRGradient.brand))
        .shadow(color: NRColor.accent.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

/// Attaches a transient confirmation toast to any view.
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    func body(content: Content) -> some View {
        ZStack {
            content
            if let message = message {
                VStack {
                    Spacer()
                    ConfirmationToast(text: message)
                        .padding(.bottom, 28)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { self.message = nil }
                    }
                }
            }
        }
    }
}

extension View {
    func nrToast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
