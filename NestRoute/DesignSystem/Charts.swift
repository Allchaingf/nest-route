//
//  Charts.swift
//  NestRoute
//
//  Hand-built charts (no external dependencies, iOS 14 compatible):
//  animated bar chart, smooth line chart, ring progress and sparkline.
//

import SwiftUI

// MARK: - Data point

struct ChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

// MARK: - Bar chart

struct BarChartView: View {
    let points: [ChartPoint]
    var tint: Color = NRColor.accent
    var height: CGFloat = 150
    @State private var animate = false

    private var maxValue: Double { max(points.map { $0.value }.max() ?? 1, 1) }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(points) { point in
                    VStack(spacing: 6) {
                        Text(shortValue(point.value))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(NRColor.textMuted)
                            .opacity(animate ? 1 : 0)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(NRGradient.pair(tint, tint.opacity(0.55)))
                            .frame(height: animate ? barHeight(point.value) : 2)
                        Text(point.label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(NRColor.textMuted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: height)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) { animate = true }
        }
        .onDisappear { animate = false }
    }

    private func barHeight(_ v: Double) -> CGFloat {
        let usable = height - 34
        return max(CGFloat(v / maxValue) * usable, 3)
    }
    private func shortValue(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1fk", v / 1000) : String(Int(v))
    }
}

// MARK: - Line chart

struct LineChartView: View {
    let points: [ChartPoint]
    var tint: Color = NRColor.blue
    var height: CGFloat = 160
    @State private var progress: CGFloat = 0

    private var values: [Double] { points.map { $0.value } }
    private var maxValue: Double { max(values.max() ?? 1, 1) }
    private var minValue: Double { values.min() ?? 0 }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height - 22

            ZStack(alignment: .topLeading) {
                // grid lines
                VStack(spacing: 0) {
                    ForEach(0..<4) { _ in
                        Rectangle().fill(NRColor.hairline).frame(height: 1)
                        Spacer()
                    }
                }
                .frame(height: h)

                // area fill
                areaPath(width: w, height: h)
                    .fill(NRGradient.pair(tint.opacity(0.28), tint.opacity(0.0)))
                    .opacity(Double(progress))

                // line stroke
                linePath(width: w, height: h)
                    .trim(from: 0, to: progress)
                    .stroke(NRGradient.pair(tint, tint.opacity(0.7)),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                // dots
                ForEach(Array(points.enumerated()), id: \.offset) { idx, _ in
                    let p = pointPosition(idx, width: w, height: h)
                    Circle()
                        .fill(NRColor.surface)
                        .overlay(Circle().stroke(tint, lineWidth: 2.5))
                        .frame(width: 8, height: 8)
                        .position(x: p.x, y: p.y)
                        .opacity(Double(progress))
                }

                // labels
                HStack {
                    ForEach(points) { point in
                        Text(point.label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(NRColor.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: w)
                .offset(y: h + 8)
            }
        }
        .frame(height: height)
        .onAppear { withAnimation(.easeInOut(duration: 1.0)) { progress = 1 } }
        .onDisappear { progress = 0 }
    }

    private func pointPosition(_ idx: Int, width: CGFloat, height: CGFloat) -> CGPoint {
        guard points.count > 1 else { return CGPoint(x: width / 2, y: height / 2) }
        let x = width * CGFloat(idx) / CGFloat(points.count - 1)
        let range = maxValue - minValue
        let norm = range == 0 ? 0.5 : (values[idx] - minValue) / range
        let y = height - CGFloat(norm) * height
        return CGPoint(x: x, y: y)
    }

    private func linePath(width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            guard !points.isEmpty else { return }
            let first = pointPosition(0, width: width, height: height)
            path.move(to: first)
            for idx in 1..<points.count {
                path.addLine(to: pointPosition(idx, width: width, height: height))
            }
        }
    }

    private func areaPath(width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            guard !points.isEmpty else { return }
            let first = pointPosition(0, width: width, height: height)
            path.move(to: CGPoint(x: first.x, y: height))
            path.addLine(to: first)
            for idx in 1..<points.count {
                path.addLine(to: pointPosition(idx, width: width, height: height))
            }
            let last = pointPosition(points.count - 1, width: width, height: height)
            path.addLine(to: CGPoint(x: last.x, y: height))
            path.closeSubpath()
        }
    }
}

// MARK: - Ring progress

struct RingProgress: View {
    let value: Double        // 0...1
    var size: CGFloat = 120
    var lineWidth: CGFloat = 14
    var tint: Color = NRColor.accent
    var label: String? = nil
    var caption: String? = nil
    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(NRColor.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(animated, 0), 1)))
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [tint, tint.opacity(0.6), tint]),
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                if let label = label {
                    Text(label)
                        .font(.system(size: size * 0.24, weight: .heavy, design: .rounded))
                        .foregroundColor(NRColor.textPrimary)
                }
                if let caption = caption {
                    Text(caption)
                        .font(.system(size: size * 0.1, weight: .semibold, design: .rounded))
                        .foregroundColor(NRColor.textMuted)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear { withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) { animated = value } }
        .onChange(of: value) { newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { animated = newValue }
        }
        .onDisappear { animated = 0 }
    }
}

// MARK: - Sparkline (mini line)

struct Sparkline: View {
    let values: [Double]
    var tint: Color = NRColor.accent
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxV = max(values.max() ?? 1, 1)
            let minV = values.min() ?? 0
            Path { path in
                guard values.count > 1 else { return }
                for (idx, v) in values.enumerated() {
                    let x = w * CGFloat(idx) / CGFloat(values.count - 1)
                    let range = maxV - minV
                    let norm = range == 0 ? 0.5 : (v - minV) / range
                    let y = h - CGFloat(norm) * h
                    if idx == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Segmented horizontal bar (distribution)

struct DistributionBar: View {
    struct Segment: Identifiable { let id = UUID(); let value: Double; let color: Color; let label: String }
    let segments: [Segment]
    @State private var animate = false

    private var total: Double { max(segments.map { $0.value }.reduce(0, +), 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(segments) { seg in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(seg.color)
                            .frame(width: animate ? geo.size.width * CGFloat(seg.value / total) - 2 : 0)
                    }
                }
            }
            .frame(height: 14)

            FlowRow(spacing: 12) {
                ForEach(segments) { seg in
                    HStack(spacing: 6) {
                        Circle().fill(seg.color).frame(width: 8, height: 8)
                        Text("\(seg.label) · \(Int(seg.value))")
                            .font(NRFont.caption)
                            .foregroundColor(NRColor.textMuted)
                    }
                }
            }
        }
        .onAppear { withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) { animate = true } }
        .onDisappear { animate = false }
    }
}

// MARK: - Simple wrapping row

struct FlowRow<Content: View>: View {
    var spacing: CGFloat = 8
    let content: Content
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    var body: some View {
        // Lightweight wrap using HStack rows; good enough for legends.
        HStack(spacing: spacing) { content }
    }
}
