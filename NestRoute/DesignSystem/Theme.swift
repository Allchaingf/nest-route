//
//  Theme.swift
//  NestRoute
//
//  Central design system: adaptive color palette, gradients, typography,
//  spacing and shadow tokens. Every color is defined as a light/dark pair
//  so the whole app re-skins instantly when the color scheme changes.
//

import SwiftUI

// MARK: - Color hex helpers

extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

extension Color {
    /// Solid color from a 0xRRGGBB literal.
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    /// Adaptive color that automatically resolves for light / dark scheme,
    /// including when the scheme is forced via `.preferredColorScheme`.
    static func adaptive(light: UInt, dark: UInt) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
        })
    }
}

// MARK: - Palette

enum NRColor {
    // Backgrounds
    static let bgTop      = Color.adaptive(light: 0xFFFBEB, dark: 0x0A1711)
    static let bgBottom   = Color.adaptive(light: 0xF7FDF9, dark: 0x06110C)

    // Surfaces / cards
    static let surface    = Color.adaptive(light: 0xFFFFFF, dark: 0x122A1E)
    static let surfaceAlt = Color.adaptive(light: 0xF1FAF4, dark: 0x173A28)
    static let hairline   = Color.adaptive(light: 0xE3EFE7, dark: 0x21402F)

    // Brand accents (green)
    static let accent     = Color.adaptive(light: 0x22C55E, dark: 0x2BD46C)
    static let accentDeep = Color.adaptive(light: 0x16A34A, dark: 0x16A34A)

    // Secondary accent (gold)
    static let gold       = Color.adaptive(light: 0xFACC15, dark: 0xFACC15)
    static let goldDeep   = Color.adaptive(light: 0xEAB308, dark: 0xCA9A07)

    // Structural (blue / cyan)
    static let blue       = Color.adaptive(light: 0x3B82F6, dark: 0x60A5FA)
    static let cyan       = Color.adaptive(light: 0x22D3EE, dark: 0x22D3EE)

    // Status
    static let ok         = Color.adaptive(light: 0x22C55E, dark: 0x34D399)
    static let warn       = Color.adaptive(light: 0xEAB308, dark: 0xFBBF24)
    static let danger     = Color.adaptive(light: 0xEF4444, dark: 0xF87171)

    // Text
    static let textPrimary   = Color.adaptive(light: 0x064E3B, dark: 0xECFDF5)
    static let textSecondary = Color.adaptive(light: 0x065F46, dark: 0xA7F3D0)
    static let textMuted     = Color.adaptive(light: 0x4B7A66, dark: 0x6B9E84)

    // On-accent (text/icons sitting on a green button)
    static let onAccent   = Color.white
}

// MARK: - Gradients

enum NRGradient {
    static let appBackground = LinearGradient(
        colors: [NRColor.bgTop, NRColor.bgBottom],
        startPoint: .top, endPoint: .bottom
    )

    static let brand = LinearGradient(
        colors: [NRColor.accent, NRColor.accentDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let sun = LinearGradient(
        colors: [NRColor.gold, NRColor.goldDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let sky = LinearGradient(
        colors: [NRColor.blue, NRColor.cyan],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let splash = LinearGradient(
        colors: [
            Color.adaptive(light: 0x16A34A, dark: 0x064E3B),
            Color.adaptive(light: 0x22C55E, dark: 0x0A1711)
        ],
        startPoint: .top, endPoint: .bottom
    )

    /// Build a gradient from any two flat colors.
    static func pair(_ a: Color, _ b: Color) -> LinearGradient {
        LinearGradient(colors: [a, b], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Typography

enum NRFont {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let largeTitle = rounded(30, .heavy)
    static let title      = rounded(24, .bold)
    static let title2     = rounded(20, .bold)
    static let headline   = rounded(17, .semibold)
    static let body       = rounded(15, .regular)
    static let callout    = rounded(14, .medium)
    static let caption    = rounded(12, .medium)
    static let tiny       = rounded(10, .semibold)
}

// MARK: - Layout tokens

enum NRSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
    static let xl: CGFloat = 30
}

enum NRRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 26
    static let pill: CGFloat = 999
}

// MARK: - Shadow

extension View {
    func nrSoftShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
    func nrTightShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}
