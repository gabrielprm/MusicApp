//
//  AudioVisualizerView.swift
//  MusicApp
//
//  Created on January 28, 2026.
//

import SwiftUI

struct AudioVisualizerView: View {
    
    /// The frequency magnitudes to visualize (0.0 to 1.0 range)
    let magnitudes: [Float]
    
    var style: VisualizerStyle = .bars

    var gradient: LinearGradient = LinearGradient(
        colors: [.purple, .blue, .cyan],
        startPoint: .bottom,
        endPoint: .top
    )

    var barSpacing: CGFloat = 2
    
    var barCornerRadius: CGFloat = 2
    
    var minBarHeight: CGFloat = 0.02
    
    var body: some View {
        GeometryReader { geometry in
            switch style {
            case .bars:
                barsView(in: geometry)
            case .wave:
                waveView(in: geometry)
            case .mirror:
                mirrorView(in: geometry)
            case .circular:
                circularView(in: geometry)
            }
        }
    }
    
    // MARK: - Bar Visualizer
    
    @ViewBuilder
    private func barsView(in geometry: GeometryProxy) -> some View {
        HStack(alignment: .bottom, spacing: barSpacing) {
            ForEach(0..<magnitudes.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: barCornerRadius)
                    .fill(gradient)
                    .frame(height: barHeight(for: index, in: geometry.size.height))
                    .animation(.easeOut(duration: 0.08), value: magnitudes[index])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    
    // MARK: - Wave Visualizer
    
    @ViewBuilder
    private func waveView(in geometry: GeometryProxy) -> some View {
        WaveShape(magnitudes: magnitudes)
            .fill(gradient)
            .animation(.easeOut(duration: 0.08), value: magnitudes)
    }
    
    // MARK: - Mirror Visualizer
    
    @ViewBuilder
    private func mirrorView(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .top, spacing: barSpacing) {
                ForEach(0..<magnitudes.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: barCornerRadius)
                        .fill(gradient)
                        .frame(height: barHeight(for: index, in: geometry.size.height / 2))
                        .animation(.easeOut(duration: 0.08), value: magnitudes[index])
                }
            }
            .frame(maxHeight: geometry.size.height / 2, alignment: .bottom)
            .scaleEffect(y: -1)
            
            HStack(alignment: .top, spacing: barSpacing) {
                ForEach(0..<magnitudes.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: barCornerRadius)
                        .fill(gradient)
                        .frame(height: barHeight(for: index, in: geometry.size.height / 2))
                        .animation(.easeOut(duration: 0.08), value: magnitudes[index])
                }
            }
            .frame(maxHeight: geometry.size.height / 2, alignment: .top)
        }
    }
    
    // MARK: - Circular Visualizer
    
    @ViewBuilder
    private func circularView(in geometry: GeometryProxy) -> some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 3
        
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)
            
            ForEach(0..<magnitudes.count, id: \.self) { index in
                CircularBar(
                    index: index,
                    total: magnitudes.count,
                    magnitude: CGFloat(magnitudes[index]),
                    innerRadius: radius,
                    maxBarLength: radius * 0.8
                )
                .fill(gradient)
                .animation(.easeOut(duration: 0.08), value: magnitudes[index])
            }
        }
        .position(center)
    }
    
    // MARK: - Helpers
    
    private func barHeight(for index: Int, in maxHeight: CGFloat) -> CGFloat {
        let magnitude = CGFloat(magnitudes[index])
        let height = max(minBarHeight, magnitude) * maxHeight
        return height
    }
}

// MARK: - Visualizer Style

enum VisualizerStyle: String, CaseIterable, Identifiable {
    case bars = "Bars"
    case wave = "Wave"
    case mirror = "Mirror"
    case circular = "Circular"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .bars: return "chart.bar.fill"
        case .wave: return "waveform"
        case .mirror: return "arrow.up.arrow.down"
        case .circular: return "circle.circle"
        }
    }
}

// MARK: - Wave Shape

struct WaveShape: Shape {
    var magnitudes: [Float]
    
    var animatableData: AnimatableVector {
        get { AnimatableVector(values: magnitudes.map { Double($0) }) }
        set { magnitudes = newValue.values.map { Float($0) } }
    }
    
    func path(in rect: CGRect) -> Path {
        guard magnitudes.count > 1 else { return Path() }
        
        var path = Path()
        let stepX = rect.width / CGFloat(magnitudes.count - 1)
        
        path.move(to: CGPoint(x: 0, y: rect.height))
        
        for (index, magnitude) in magnitudes.enumerated() {
            let x = CGFloat(index) * stepX
            let y = rect.height - (CGFloat(magnitude) * rect.height)
            
            if index == 0 {
                path.addLine(to: CGPoint(x: x, y: y))
            } else {
                let prevX = CGFloat(index - 1) * stepX
                let prevY = rect.height - (CGFloat(magnitudes[index - 1]) * rect.height)
                let controlX = (prevX + x) / 2
                
                path.addCurve(
                    to: CGPoint(x: x, y: y),
                    control1: CGPoint(x: controlX, y: prevY),
                    control2: CGPoint(x: controlX, y: y)
                )
            }
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Animatable Vector

struct AnimatableVector: VectorArithmetic {
    var values: [Double]
    
    static var zero: AnimatableVector {
        AnimatableVector(values: [])
    }
    
    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let maxCount = max(lhs.values.count, rhs.values.count)
        var result = [Double](repeating: 0, count: maxCount)
        for i in 0..<maxCount {
            let lVal = i < lhs.values.count ? lhs.values[i] : 0
            let rVal = i < rhs.values.count ? rhs.values[i] : 0
            result[i] = lVal + rVal
        }
        return AnimatableVector(values: result)
    }
    
    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let maxCount = max(lhs.values.count, rhs.values.count)
        var result = [Double](repeating: 0, count: maxCount)
        for i in 0..<maxCount {
            let lVal = i < lhs.values.count ? lhs.values[i] : 0
            let rVal = i < rhs.values.count ? rhs.values[i] : 0
            result[i] = lVal - rVal
        }
        return AnimatableVector(values: result)
    }
    
    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }
    
    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }
}

// MARK: - Circular Bar Shape

struct CircularBar: Shape {
    let index: Int
    let total: Int
    let magnitude: CGFloat
    let innerRadius: CGFloat
    let maxBarLength: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let angle = (CGFloat(index) / CGFloat(total)) * 2 * .pi - .pi / 2
        let barLength = max(4, magnitude * maxBarLength)
        
        let startPoint = CGPoint(
            x: center.x + cos(angle) * innerRadius,
            y: center.y + sin(angle) * innerRadius
        )
        
        let endPoint = CGPoint(
            x: center.x + cos(angle) * (innerRadius + barLength),
            y: center.y + sin(angle) * (innerRadius + barLength)
        )
        
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        return path.strokedPath(StrokeStyle(lineWidth: 3, lineCap: .round))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            AudioVisualizerView(
                magnitudes: (0..<64).map { _ in Float.random(in: 0.1...1.0) },
                style: .bars
            )
            .frame(height: 100)
            
            AudioVisualizerView(
                magnitudes: (0..<64).map { _ in Float.random(in: 0.1...1.0) },
                style: .mirror
            )
            .frame(height: 100)
            
            AudioVisualizerView(
                magnitudes: (0..<64).map { _ in Float.random(in: 0.1...1.0) },
                style: .circular
            )
            .frame(height: 200)
        }
        .padding()
    }
}
