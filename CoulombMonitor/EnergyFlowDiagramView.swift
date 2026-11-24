//
//  EnergyFlowDiagramView.swift
//  CoulombMonitor
//

import SwiftUI

struct EnergyFlowDiagramView: View {
    let info: BatteryInfo
    
    private var flow: EnergyFlowSnapshot {
        info.energyFlow
    }
    
    var body: some View {
        VStack(spacing: 8) {
            diagramHeader
            diagramCanvas
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }
    
    // MARK: - Header
    
    private var diagramHeader: some View {
        HStack {
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(EnergyPalette.sky)
                Text("リアルタイム電力フロー")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.65))
            }
            
            Spacer()
            
            Text(adapterBadgeText)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(adapterBadgeForeground)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.11), lineWidth: 0.75)
                )
        }
    }
    
    private var adapterBadgeText: String {
        guard info.hasExternalPower else {
            return "外部電源 未接続"
        }
        let ratedPrefix: String
        if let watts = info.adapterWatts, watts > 0 {
            ratedPrefix = "PD \(watts)W"
        } else {
            ratedPrefix = "外部電源"
        }
        
        switch flow.mode {
        case .charging:
            return info.adapterWatts != nil ? "\(ratedPrefix) アダプタ" : "外部電源 接続中"
        case .batteryAssist:
            return "\(ratedPrefix) 最大出力"
        case .bypass:
            return info.isFullyCharged ? "\(ratedPrefix) バイパス" : "\(ratedPrefix) 給電中"
        case .onBattery:
            return "外部電源 未接続"
        }
    }
    
    private var adapterBadgeForeground: Color {
        info.hasExternalPower ? Color.white.opacity(0.8) : Color.white.opacity(0.5)
    }
    
    // MARK: - Diagram Canvas & Nodes
    
    private var diagramCanvas: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / 360.0
            let scaleY = geometry.size.height / 242.0
            let scale = min(scaleX, scaleY)
            let offsetX = (geometry.size.width - 360.0 * scale) / 2.0
            let offsetY = (geometry.size.height - 242.0 * scale) / 2.0
            
            ZStack(alignment: .topLeading) {
                flowPathsLayer
                
                externalPowerNode
                    .position(x: 180, y: 42)
                
                batteryNode
                    .position(x: 60, y: 184)
                
                systemNode
                    .position(x: 300, y: 184)
                
                flowPill(
                    watts: flow.externalToBatteryWatts,
                    accent: EnergyPalette.emerald,
                    textColor: EnergyPalette.emeraldBright
                )
                .position(x: 84, y: 100)
                
                flowPill(
                    watts: flow.externalToSystemWatts,
                    accent: EnergyPalette.sky,
                    textColor: EnergyPalette.skyBright
                )
                .position(x: 276, y: 100)
                
                flowPill(
                    watts: flow.batteryToSystemWatts,
                    accent: EnergyPalette.amber,
                    textColor: EnergyPalette.amberBright
                )
                .position(x: 176, y: 188)
            }
            .frame(width: 360, height: 242)
            .scaleEffect(scale, anchor: .topLeading)
            .offset(x: offsetX, y: offsetY)
        }
        .frame(height: 238)
    }
    
    // MARK: - Animated Flow Paths
    
    private var hasActiveFlow: Bool {
        flow.externalToBatteryWatts > 0.05
            || flow.externalToSystemWatts > 0.05
            || flow.batteryToSystemWatts > 0.05
    }
    
    private var flowPathsLayer: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !hasActiveFlow)) { timeline in
            Canvas { context, _ in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                
                let extToBatPath = Path { path in
                    path.move(to: CGPoint(x: 146, y: 62))
                    path.addCurve(
                        to: CGPoint(x: 64, y: 142),
                        control1: CGPoint(x: 94, y: 72),
                        control2: CGPoint(x: 68, y: 102)
                    )
                }
                
                let extToSysPath = Path { path in
                    path.move(to: CGPoint(x: 214, y: 62))
                    path.addCurve(
                        to: CGPoint(x: 296, y: 142),
                        control1: CGPoint(x: 266, y: 72),
                        control2: CGPoint(x: 292, y: 102)
                    )
                }
                
                let batToSysPath = Path { path in
                    path.move(to: CGPoint(x: 98, y: 188))
                    path.addLine(to: CGPoint(x: 250, y: 188))
                }
                
                // Base dim tracks
                let trackStyle = StrokeStyle(lineWidth: 4, lineCap: .round)
                let trackColor = GraphicsContext.Shading.color(Color.white.opacity(0.08))
                context.stroke(extToBatPath, with: trackColor, style: trackStyle)
                context.stroke(extToSysPath, with: trackColor, style: trackStyle)
                context.stroke(batToSysPath, with: trackColor, style: trackStyle)
                
                // Active energy streams
                if flow.externalToBatteryWatts > 0.05 {
                    let speed = flowSpeedPointsPerSecond(watts: flow.externalToBatteryWatts, numerator: 60.0, minPeriod: 0.45, maxPeriod: 1.4)
                    drawAnimatedFlow(
                        in: &context,
                        path: extToBatPath,
                        color: EnergyPalette.emerald,
                        elapsed: elapsed,
                        speed: speed
                    )
                }
                
                if flow.externalToSystemWatts > 0.05 {
                    let speed = flowSpeedPointsPerSecond(watts: flow.externalToSystemWatts, numerator: 25.0, minPeriod: 0.40, maxPeriod: 1.4)
                    drawAnimatedFlow(
                        in: &context,
                        path: extToSysPath,
                        color: EnergyPalette.sky,
                        elapsed: elapsed,
                        speed: speed,
                        lineWidth: 3.0
                    )
                }
                
                if flow.batteryToSystemWatts > 0.05 {
                    let speed = flowSpeedPointsPerSecond(watts: flow.batteryToSystemWatts, numerator: 22.0, minPeriod: 0.45, maxPeriod: 1.4)
                    drawAnimatedFlow(
                        in: &context,
                        path: batToSysPath,
                        color: EnergyPalette.amber,
                        elapsed: elapsed,
                        speed: speed
                    )
                }
            }
            .frame(width: 360, height: 242)
        }
    }
    
    private func flowSpeedPointsPerSecond(watts: Double, numerator: Double, minPeriod: Double, maxPeriod: Double) -> Double {
        let period = min(maxPeriod, max(minPeriod, numerator / max(1.0, watts)))
        return 24.0 / period
    }
    
    private func drawAnimatedFlow(
        in context: inout GraphicsContext,
        path: Path,
        color: Color,
        elapsed: TimeInterval,
        speed: Double,
        lineWidth: CGFloat = 3.5
    ) {
        let phase = -CGFloat((elapsed * speed).truncatingRemainder(dividingBy: 12.0))
        
        // Soft glow halo
        context.drawLayer { layerContext in
            layerContext.addFilter(.blur(radius: 3.2))
            layerContext.stroke(
                path,
                with: .color(color.opacity(0.55)),
                style: StrokeStyle(lineWidth: lineWidth + 2.0, lineCap: .round, dash: [6, 6], dashPhase: phase)
            )
        }
        
        // Crisp dashed energy stream
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [6, 6], dashPhase: phase)
        )
    }
    
    // MARK: - Nodes
    
    private var externalPowerNode: some View {
        let isActive = flow.externalTotalWatts > 0.05 || info.hasExternalPower
        let accent = isActive ? EnergyPalette.emeraldBright : Color.white.opacity(0.35)
        
        return ZStack {
            if isActive {
                Circle()
                    .fill(EnergyPalette.emerald.opacity(0.16))
                    .frame(width: 72, height: 72)
                    .blur(radius: 10)
            }
            
            VStack(spacing: 3) {
                Image(systemName: "powerplug.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isActive ? EnergyPalette.emeraldBright : Color.white.opacity(0.35))
                
                Text("外部電源")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(isActive ? 0.78 : 0.45))
                
                Text(String(format: "%.2f W", flow.externalTotalWatts))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.4))
                    .monospacedDigit()
            }
            .frame(width: 94, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(EnergyPalette.nodeBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isActive ? accent.opacity(0.48) : Color.white.opacity(0.12), lineWidth: 1.4)
            )
        }
    }
    
    private var batteryNode: some View {
        let accent = batteryAccentColor
        let fillFraction = CGFloat(min(100, max(4, info.percentage))) / 100.0
        
        return ZStack {
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: 76, height: 76)
                .blur(radius: 11)
            
            VStack(spacing: 0) {
                // Battery Terminal Cap
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 24, height: 4.5)
                    .padding(.bottom, 1.5)
                
                // Battery Body with Liquid Level
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(EnergyPalette.batteryNodeBackground)
                    
                    // Liquid level fill
                    GeometryReader { geo in
                        let liquidHeight = max(4, geo.size.height * fillFraction)
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            ZStack(alignment: .top) {
                                Rectangle()
                                    .fill(accent.opacity(0.36))
                                    .frame(height: liquidHeight)
                                
                                // Meniscus highlight line
                                Rectangle()
                                    .fill(accent)
                                    .frame(height: 2)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(2)
                    .animation(.easeInOut(duration: 0.5), value: info.percentage)
                    
                    // Text Overlay
                    VStack(spacing: 2) {
                        Text("バッテリー")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                        
                        Text("\(info.percentage)%")
                            .font(.system(size: 13.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white)
                            .monospacedDigit()
                        
                        Text(batteryNetLabel)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(accent)
                            .monospacedDigit()
                    }
                }
                .frame(width: 64, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.85), lineWidth: 1.6)
                )
            }
        }
    }
    
    private var batteryAccentColor: Color {
        switch flow.mode {
        case .charging:
            return EnergyPalette.emeraldBright
        case .batteryAssist:
            return EnergyPalette.amberBright
        case .onBattery:
            return info.percentage <= 20 ? EnergyPalette.rose : EnergyPalette.orangeBright
        case .bypass:
            return EnergyPalette.skyBright
        }
    }
    
    private var batteryNetLabel: String {
        switch flow.mode {
        case .charging:
            return String(format: "+%.1fW", flow.externalToBatteryWatts)
        case .batteryAssist, .onBattery:
            return String(format: "-%.1fW", flow.batteryToSystemWatts)
        case .bypass:
            return "待機 0W"
        }
    }
    
    private var systemNode: some View {
        ZStack {
            Circle()
                .fill(EnergyPalette.sky.opacity(0.16))
                .frame(width: 76, height: 76)
                .blur(radius: 10)
            
            VStack(spacing: 3) {
                Image(systemName: "cpu")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(EnergyPalette.skyBright)
                
                Text("システム")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.78))
                
                Text(String(format: "%.2f W", flow.systemTotalWatts))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .monospacedDigit()
            }
            .frame(width: 90, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(EnergyPalette.nodeBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(EnergyPalette.sky.opacity(0.45), lineWidth: 1.4)
            )
        }
    }
    
    // MARK: - Flow Wattage Pill
    
    private func flowPill(watts: Double, accent: Color, textColor: Color) -> some View {
        let isActive = watts > 0.05
        let label = isActive ? String(format: "%.2f W", watts) : "0 W"
        
        return Text(label)
            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(isActive ? textColor : Color.white.opacity(0.38))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(isActive ? EnergyPalette.pillActiveBackground : EnergyPalette.pillInactiveBackground)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isActive ? accent : Color.white.opacity(0.13), lineWidth: isActive ? 1.2 : 1.0)
            )
            .shadow(color: isActive ? accent.opacity(0.22) : .clear, radius: 5, y: 1)
    }
}

// MARK: - Shared Color Palette

enum EnergyPalette {
    static let emerald = Color(red: 0.06, green: 0.73, blue: 0.51)       // #10b981
    static let emeraldBright = Color(red: 0.20, green: 0.83, blue: 0.60) // #34d399
    static let sky = Color(red: 0.22, green: 0.74, blue: 0.97)           // #38bdf8
    static let skyBright = Color(red: 0.49, green: 0.83, blue: 0.99)     // #7dd3fc
    static let amber = Color(red: 0.96, green: 0.62, blue: 0.04)         // #f59e0b
    static let amberBright = Color(red: 0.98, green: 0.75, blue: 0.14)   // #fbbf24
    static let orange = Color(red: 0.98, green: 0.45, blue: 0.09)        // #f97316
    static let orangeBright = Color(red: 0.98, green: 0.57, blue: 0.24)  // #fb923c
    static let rose = Color(red: 0.96, green: 0.25, blue: 0.37)          // #f43f5e
    
    static let popoverBackground = Color(red: 0.09, green: 0.10, blue: 0.14)
    static let nodeBackground = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let batteryNodeBackground = Color(red: 0.08, green: 0.10, blue: 0.14)
    static let pillActiveBackground = Color(red: 0.06, green: 0.09, blue: 0.16)
    static let pillInactiveBackground = Color(red: 0.08, green: 0.09, blue: 0.13)
}
