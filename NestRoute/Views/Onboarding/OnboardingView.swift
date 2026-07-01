//
//  OnboardingView.swift
//  NestRoute
//
//  Three illustrated onboarding screens, each with a distinct interactive
//  element:
//    1. Smart control   – tap the hub to burst particles
//    2. Track everything – drag the bird marker along the route
//    3. Save time        – tilt-parallax (gyroscope) layered cards
//
//  Skip + Next always visible, custom dot indicators, completion saved by
//  the parent via onFinish(). All looping animations reset on disappear.
//

import SwiftUI
import CoreMotion

// MARK: - Motion manager (gyroscope parallax)

final class MotionManager: ObservableObject {
    @Published var roll: Double = 0
    @Published var pitch: Double = 0
    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let m = motion else { return }
            self.roll = m.attitude.roll
            self.pitch = m.attitude.pitch
        }
    }
    func stop() {
        manager.stopDeviceMotionUpdates()
        roll = 0; pitch = 0
    }
}

// MARK: - Container

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        ZStack {
            NRGradient.appBackground.ignoresSafeArea()

            TabView(selection: $page) {
                OnboardingSmartControl().tag(0)
                OnboardingTrackEverything().tag(1)
                OnboardingSaveTime().tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: page)

            // Controls overlay
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { Haptics.tap(); onFinish() }
                        .font(NRFont.callout)
                        .foregroundColor(NRColor.textMuted)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(NRColor.surface))
                        .overlay(Capsule().stroke(NRColor.hairline, lineWidth: 1))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? NRColor.accent : NRColor.hairline)
                            .frame(width: i == page ? 26 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.bottom, 14)

                PrimaryButton(title: page == 2 ? "Let's go" : "Next",
                              icon: page == 2 ? "checkmark" : "arrow.right") {
                    if page == 2 { onFinish() }
                    else { withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { page += 1 } }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Reusable text block

private struct OnboardingCaption: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(NRColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(NRFont.body)
                .foregroundColor(NRColor.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
        }
    }
}

// MARK: - Screen 1: Smart control (tap to burst)

private struct OnboardingSmartControl: View {
    @State private var burst = false
    @State private var pulse = false
    @State private var rotate = false

    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(NRColor.accent.opacity(0.18), lineWidth: 2)
                        .frame(width: 150 + CGFloat(i) * 50, height: 150 + CGFloat(i) * 50)
                        .scaleEffect(pulse ? 1.06 : 0.97)
                }

                // bursting particles
                ForEach(0..<10, id: \.self) { i in
                    Circle()
                        .fill(i.isMultiple(of: 2) ? NRColor.accent : NRColor.gold)
                        .frame(width: 12, height: 12)
                        .offset(burstOffset(i))
                        .opacity(burst ? 0 : 1)
                        .scaleEffect(burst ? 0.4 : 1)
                }

                // dashed orbit
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 9]))
                    .foregroundColor(NRColor.accent.opacity(0.5))
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(rotate ? 360 : 0))

                // hub button
                Button(action: triggerBurst) {
                    ZStack {
                        Circle().fill(NRGradient.brand).frame(width: 96, height: 96)
                            .shadow(color: NRColor.accent.opacity(0.4), radius: 14, y: 8)
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(burst ? 1.18 : 1)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(height: 300)

            OnboardingCaption(
                title: "Smart control",
                subtitle: "Plan, adjust and monitor every transport from one calm, focused hub. Tap to feel it respond.")
        }
        .padding(.top, 40)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) { rotate = true }
        }
        .onDisappear { pulse = false; rotate = false; burst = false }
    }

    private func burstOffset(_ i: Int) -> CGSize {
        let angle = Double(i) / 10.0 * 2 * Double.pi
        let r: CGFloat = burst ? 150 : 0
        return CGSize(width: CGFloat(cos(angle)) * r, height: CGFloat(sin(angle)) * r)
    }

    private func triggerBurst() {
        Haptics.tap(.medium)
        burst = false
        withAnimation(.easeOut(duration: 0.7)) { burst = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            burst = false
        }
    }
}

// MARK: - Screen 2: Track everything (drag the marker)

private struct OnboardingTrackEverything: View {
    @State private var progress: CGFloat = 0.15
    @State private var floatY = false

    var body: some View {
        VStack(spacing: 40) {
            GeometryReader { geo in
                let width = geo.size.width - 80
                ZStack {
                    // route track
                    Capsule()
                        .fill(NRColor.hairline)
                        .frame(width: width, height: 8)
                    Capsule()
                        .fill(NRGradient.brand)
                        .frame(width: width * progress, height: 8)
                        .frame(width: width, alignment: .leading)

                    // stop markers
                    ForEach(0..<5, id: \.self) { i in
                        let f = CGFloat(i) / 4
                        Circle()
                            .fill(f <= progress ? NRColor.accent : NRColor.surface)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(NRColor.accent, lineWidth: 2))
                            .offset(x: -width/2 + width * f)
                    }

                    // draggable bird marker
                    ZStack {
                        Circle().fill(NRColor.surface).frame(width: 56, height: 56)
                            .overlay(Circle().stroke(NRColor.accent, lineWidth: 3))
                            .nrSoftShadow()
                        BirdGlyph(size: 26, color: NRColor.accentDeep)
                    }
                    .offset(x: -width/2 + width * progress, y: floatY ? -4 : 4)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let x = value.location.x
                                progress = min(max((x) / width, 0), 1)
                                Haptics.tap(.light)
                            }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 260)

            VStack(spacing: 8) {
                Text("\(Int(progress * 100))% of route")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(NRColor.accentDeep)
                OnboardingCaption(
                    title: "Track everything",
                    subtitle: "Drag the marker — follow every group, stop and welfare check live along the route.")
            }
        }
        .padding(.top, 40)
        .onAppear { withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { floatY = true } }
        .onDisappear { floatY = false }
    }
}

// MARK: - Screen 3: Save time (gyroscope parallax)

private struct OnboardingSaveTime: View {
    @StateObject private var motion = MotionManager()
    @State private var sway = false

    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                // Back layer
                parallaxCard(icon: "calendar", color: NRColor.blue, w: 150, h: 110)
                    .offset(x: shift(0.6) - 70, y: -40)
                    .rotationEffect(.degrees(-8))
                // Mid layer
                parallaxCard(icon: "chart.bar.fill", color: NRColor.gold, w: 150, h: 110)
                    .offset(x: shift(1.0) + 70, y: 30)
                    .rotationEffect(.degrees(7))
                // Front layer (clock)
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(NRGradient.brand)
                        .frame(width: 150, height: 150)
                        .shadow(color: NRColor.accent.opacity(0.4), radius: 18, y: 10)
                    Image(systemName: "clock.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: shift(1.6), y: shiftY(1.6))
            }
            .frame(height: 300)

            OnboardingCaption(
                title: "Save time",
                subtitle: "Tilt your phone to explore. Automatic schedules, reminders and reports do the busywork for you.")
        }
        .padding(.top, 40)
        .onAppear {
            motion.start()
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { sway = true }
        }
        .onDisappear {
            motion.stop()
            sway = false
        }
    }

    // Real gyro parallax, with a gentle auto-sway fallback for devices
    // without motion (e.g. simulator).
    private func shift(_ depth: Double) -> CGFloat {
        let gyro = CGFloat(motion.roll) * 60 * CGFloat(depth)
        let fallback: CGFloat = (sway ? 10 : -10) * CGFloat(depth)
        return motion.roll == 0 ? fallback : gyro
    }
    private func shiftY(_ depth: Double) -> CGFloat {
        let gyro = CGFloat(motion.pitch) * 40 * CGFloat(depth)
        return motion.pitch == 0 ? 0 : gyro
    }

    private func parallaxCard(icon: String, color: Color, w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(NRColor.surface)
                .frame(width: w, height: h)
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(NRColor.hairline, lineWidth: 1))
                .nrSoftShadow()
            Image(systemName: icon)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(color)
        }
    }
}
