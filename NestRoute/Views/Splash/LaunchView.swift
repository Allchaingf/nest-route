//
//  LaunchView.swift
//  NestRoute
//
//  Thematic splash: a flock of birds drifting along a route while feathers
//  rise, an orbiting "route ring" circles the nest logo, and the title makes
//  a spring entrance before a designed scale-up-and-fade exit.
//
//  Three simultaneously animated layers:
//    1. Background gradient + breathing radial glow
//    2. Midground drifting birds + rising feathers
//    3. Foreground logo badge + orbiting ring + title entrance
//
//  A single coordinator timer stages the sequence; all looping animations
//  are reset on disappear so nothing leaks into the main app.
//

import SwiftUI

struct LaunchView: View {
    @Binding var isActive: Bool

    // Loop / phase flags
    @State private var isVisible = true
    @State private var glow = false
    @State private var ringSpin = false
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var exiting = false

    // Single coordinator timer
    @State private var coordinator: Timer?
    @State private var elapsed: Double = 0

    var body: some View {
        ZStack {
            // ---- Layer 1: background ----
            NRGradient.splash.ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [NRColor.gold.opacity(0.45), Color.clear]),
                center: .center, startRadius: 10, endRadius: glow ? 360 : 220)
                .scaleEffect(glow ? 1.15 : 0.9)
                .opacity(glow ? 0.9 : 0.5)
                .ignoresSafeArea()

            // ---- Layer 2: midground ----
            ForEach(0..<6, id: \.self) { i in
                FloatingFeather(index: i, isVisible: $isVisible)
            }
            ForEach(0..<3, id: \.self) { i in
                DriftingBird(index: i, isVisible: $isVisible)
            }

            // ---- Layer 3: foreground ----
            VStack(spacing: 18) {
                ZStack {
                    // orbiting route ring
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [3, 10]))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 132, height: 132)
                        .rotationEffect(.degrees(ringSpin ? 360 : 0))

                    // nest badge
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 104, height: 104)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 92, height: 92)
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                    BirdGlyph(size: 52, color: NRColor.accentDeep)
                        .rotationEffect(.degrees(-8))
                }
                .scaleEffect(showLogo ? (exiting ? 1.35 : 1) : 0.5)
                .opacity(showLogo ? (exiting ? 0 : 1) : 0)

                VStack(spacing: 6) {
                    Text("NestRoute")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Routes for safe bird transport")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                .opacity(showTitle ? (exiting ? 0 : 1) : 0)
                .offset(y: showTitle ? 0 : 18)
            }
            .opacity(exiting ? 0 : 1)
        }
        .onAppear(perform: start)
        .onDisappear(perform: stop)
    }

    // MARK: Sequence

    private func start() {
        isVisible = true
        // Looping layers
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { glow = true }
        withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) { ringSpin = true }
        // Staged entrance (animation delays, not nested dispatch)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(1.4)) { showLogo = true }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(1.7)) { showTitle = true }

        // Single coordinator timer handles exit + finish.
        elapsed = 0
        coordinator = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsed += 0.1
            if elapsed >= 2.35 && !exiting {
                withAnimation(.easeIn(duration: 0.45)) { exiting = true }
            }
            if elapsed >= 2.85 {
                finish()
            }
        }
    }

    private func finish() {
        coordinator?.invalidate()
        coordinator = nil
        withAnimation(.easeInOut(duration: 0.35)) { isActive = false }
    }

    private func stop() {
        coordinator?.invalidate()
        coordinator = nil
        // Reset every looping flag so animations don't leak.
        isVisible = false
        glow = false
        ringSpin = false
        showLogo = false
        showTitle = false
        exiting = false
    }
}

// MARK: - Drifting bird

private struct DriftingBird: View {
    let index: Int
    @Binding var isVisible: Bool
    @State private var x: CGFloat = -220
    @State private var bob = false

    private var yBase: CGFloat { [-180, -40, 120][index % 3] }
    private var size: CGFloat { [26, 34, 22][index % 3] }
    private var duration: Double { [9, 11, 13][index % 3] }

    var body: some View {
        BirdGlyph(size: size, color: Color.white.opacity(0.8))
            .rotationEffect(.degrees(-12))
            .offset(x: x, y: yBase + (bob ? -14 : 14))
            .onAppear {
                x = -220
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    x = UIScreen.main.bounds.width + 160
                }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    bob = true
                }
            }
            .onDisappear { x = -220; bob = false }
    }
}

// MARK: - Floating feather

private struct FloatingFeather: View {
    let index: Int
    @Binding var isVisible: Bool
    @State private var rise = false

    private var startX: CGFloat { [-120, -50, 30, 90, 140, -160][index % 6] }
    private var size: CGFloat { [10, 14, 8, 12, 9, 13][index % 6] }
    private var duration: Double { [6, 8, 7, 9, 6.5, 8.5][index % 6] }

    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: size))
            .foregroundColor(.white.opacity(0.5))
            .rotationEffect(.degrees(rise ? 40 : -30))
            .offset(x: startX + (rise ? 30 : -30), y: rise ? -360 : 360)
            .opacity(rise ? 0.0 : 0.7)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: false)) {
                    rise = true
                }
            }
            .onDisappear { rise = false }
    }
}
