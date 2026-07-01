//
//  BirdGlyph.swift
//  NestRoute
//
//  Custom bird mark. SF Symbols has no `bird` glyph before iOS 16, so the
//  app's signature bird is drawn here as a Shape — guaranteeing it renders
//  identically on iOS 14 and up. Used wherever the brand bird appears.
//

import SwiftUI

/// A symmetric flying-bird (gull) silhouette in a unit square.
struct BirdShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let ox = rect.midX - s / 2
        let oy = rect.midY - s / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }

        var path = Path()

        // Head
        path.addEllipse(in: CGRect(x: ox + 0.40 * s, y: oy + 0.03 * s, width: 0.20 * s, height: 0.20 * s))

        // Body
        path.addEllipse(in: CGRect(x: ox + 0.42 * s, y: oy + 0.22 * s, width: 0.16 * s, height: 0.46 * s))

        // Left wing
        path.move(to: p(0.50, 0.30))
        path.addQuadCurve(to: p(0.03, 0.21), control: p(0.23, 0.10))
        path.addQuadCurve(to: p(0.50, 0.52), control: p(0.25, 0.41))
        path.closeSubpath()

        // Right wing
        path.move(to: p(0.50, 0.30))
        path.addQuadCurve(to: p(0.97, 0.21), control: p(0.77, 0.10))
        path.addQuadCurve(to: p(0.50, 0.52), control: p(0.75, 0.41))
        path.closeSubpath()

        // Fan tail
        path.move(to: p(0.42, 0.62))
        path.addLine(to: p(0.50, 0.95))
        path.addLine(to: p(0.58, 0.62))
        path.closeSubpath()

        return path
    }
}

/// Filled bird mark sized to `size`, optionally on a tinted rounded backing.
struct BirdGlyph: View {
    var size: CGFloat
    var color: Color = NRColor.accent

    var body: some View {
        BirdShape()
            .fill(color)
            .frame(width: size, height: size)
    }
}
