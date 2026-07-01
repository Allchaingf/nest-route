//
//  Chrome.swift
//  NestRoute
//
//  Shared screen chrome: a custom header bar (with optional back button and
//  trailing action) and a spacer that keeps content clear of the floating
//  tab bar. Lets every screen use a fully custom navigation look on iOS 14.
//

import SwiftUI

struct NRHeaderBar: View {
    let title: String
    var subtitle: String? = nil
    var showBack: Bool = false
    var trailingIcon: String? = nil
    var trailingAction: (() -> Void)? = nil

    @Environment(\.presentationMode) private var presentation

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if showBack {
                Button {
                    Haptics.tap()
                    presentation.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(NRColor.accentDeep)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(NRColor.surface))
                        .overlay(Circle().stroke(NRColor.hairline, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NRFont.largeTitle)
                    .foregroundColor(NRColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(NRFont.callout)
                        .foregroundColor(NRColor.textMuted)
                }
            }

            Spacer(minLength: 8)

            if let icon = trailingIcon, let action = trailingAction {
                CircleIconButton(icon: icon, action: action)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

/// Keeps scroll content from being hidden behind the floating tab bar.
struct TabBarSpacer: View {
    var height: CGFloat = 96
    var body: some View { Color.clear.frame(height: height) }
}

extension View {
    /// Standard stack navigation styling (no iPad split view) + hidden system bar.
    func nrStackNavigation() -> some View {
        self.navigationViewStyle(StackNavigationViewStyle())
    }
}
