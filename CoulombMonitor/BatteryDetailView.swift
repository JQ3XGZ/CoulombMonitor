//
//  BatteryDetailView.swift
//  CoulombMonitor
//

import SwiftUI

struct BatteryDetailView: View {
    let monitor: BatteryMonitor
    
    var body: some View {
        BatteryDetailContentView(
            info: monitor.info,
            onRefresh: { monitor.refresh() }
        )
    }
}

struct BatteryDetailContentView: View {
    let info: BatteryInfo
    let onRefresh: () -> Void
    
    @State private var refreshSpinCount: Int = 0
    
    private var flow: EnergyFlowSnapshot {
        info.energyFlow
    }
    
    var body: some View {
        ZStack {
            ambientBackdrop
            
            VStack(spacing: 14) {
                headerSection
                
                EnergyFlowDiagramView(info: info)
                
                telemetryCardsSection
                
                footerSection
            }
            .padding(18)
        }
        .frame(width: 408)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Ambient Dark Glass Backdrop
    
    private var ambientBackdrop: some View {
        ZStack {
            EnergyPalette.popoverBackground
            
            RadialGradient(
                colors: [Color.orange.opacity(0.14), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 230
            )
            
            RadialGradient(
                colors: [EnergyPalette.emerald.opacity(0.12), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 230
            )
            
            RadialGradient(
                colors: [EnergyPalette.sky.opacity(0.11), .clear],
                center: .bottom,
                startRadius: 10,
                endRadius: 250
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(info.percentage)")
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text("%")
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    
                    if let health = info.healthPercentage {
                        healthPill(health: health)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    Image(systemName: headerStatusIcon)
                        .font(.system(size: 13, weight: .semibold))
                    Text(headerStatusText)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(statusAccentColor)
            }
            
            // Smooth Gradient Progress Bar
            GeometryReader { geo in
                let fraction = CGFloat(min(100, max(0, info.percentage))) / 100.0
                let barWidth = max(fraction > 0 ? 8 : 0, (geo.size.width - 4) * fraction)
                
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.09))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.07), lineWidth: 0.75)
                        )
                    
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: progressGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: barWidth)
                        .padding(2)
                        .animation(.easeInOut(duration: 0.45), value: info.percentage)
                }
            }
            .frame(height: 11)
            
            // Time Remaining & Net Wattage Row
            HStack {
                headerTimeRemainingLabel
                Spacer()
                headerNetWattageLabel
            }
            .font(.system(size: 11.5))
        }
    }
    
    private func healthPill(health: Double) -> some View {
        let isHealthy = health >= 80.0
        let pillColor = isHealthy ? EnergyPalette.emeraldBright : EnergyPalette.amberBright
        
        return Text(String(format: "健全度 %.0f%%", health))
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(pillColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(pillColor.opacity(0.15))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(pillColor.opacity(0.3), lineWidth: 0.75)
            )
    }
    
    private var headerStatusIcon: String {
        switch flow.mode {
        case .charging:
            return "bolt.fill"
        case .batteryAssist:
            return "bolt.trianglebadge.exclamationmark.fill"
        case .onBattery:
            if info.percentage >= 88 { return "battery.100percent" }
            if info.percentage >= 63 { return "battery.75percent" }
            if info.percentage >= 38 { return "battery.50percent" }
            if info.percentage >= 13 { return "battery.25percent" }
            return "battery.0percent"
        case .bypass:
            return "powerplug.fill"
        }
    }
    
    private var headerStatusText: String {
        switch flow.mode {
        case .charging:
            return String(format: "充電中 (%.1f W)", flow.externalTotalWatts)
        case .batteryAssist:
            return "高負荷・バッテリー補助"
        case .onBattery:
            return String(format: "バッテリー駆動中 (%.1f W)", flow.batteryToSystemWatts)
        case .bypass:
            return info.isFullyCharged ? "満充電 (AC直接給電)" : "外部電源接続中 (給電のみ)"
        }
    }
    
    private var statusAccentColor: Color {
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
    
    private var progressGradientColors: [Color] {
        switch flow.mode {
        case .charging:
            return [EnergyPalette.emerald, EnergyPalette.emeraldBright]
        case .batteryAssist:
            return [EnergyPalette.amber, EnergyPalette.amberBright]
        case .onBattery:
            if info.percentage <= 20 {
                return [EnergyPalette.rose, EnergyPalette.orangeBright]
            }
            return [EnergyPalette.orange, EnergyPalette.amberBright]
        case .bypass:
            return [EnergyPalette.sky, EnergyPalette.skyBright]
        }
    }
    
    @ViewBuilder
    private var headerTimeRemainingLabel: some View {
        switch flow.mode {
        case .charging:
            if let timeRemaining = info.timeRemainingFormatted {
                HStack(spacing: 4) {
                    Text("満充電まで:")
                        .foregroundStyle(Color.white.opacity(0.55))
                    Text(timeRemaining)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white.opacity(0.92))
                }
            } else {
                Text("満充電まで計算中…")
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            
        case .batteryAssist, .onBattery:
            if let timeRemaining = info.timeRemainingFormatted {
                HStack(spacing: 4) {
                    Text(flow.mode == .batteryAssist ? "残り駆動目安:" : "残り駆動時間:")
                        .foregroundStyle(Color.white.opacity(0.55))
                    Text(timeRemaining)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white.opacity(0.92))
                }
            } else {
                Text("残り時間を計算中…")
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            
        case .bypass:
            HStack(spacing: 4) {
                Text("バッテリー状態:")
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(info.isFullyCharged ? "充電完了・保護中" : "待機中・保護モード")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white.opacity(0.92))
            }
        }
    }
    
    @ViewBuilder
    private var headerNetWattageLabel: some View {
        switch flow.mode {
        case .charging:
            HStack(spacing: 4) {
                Text("正味蓄電:")
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(String(format: "+%.2f W", flow.externalToBatteryWatts))
                    .fontWeight(.semibold)
                    .foregroundStyle(EnergyPalette.emeraldBright)
                    .monospacedDigit()
            }
            .font(.system(size: 11, design: .monospaced))
            
        case .batteryAssist:
            HStack(spacing: 4) {
                Text("バッテリー補助:")
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(String(format: "-%.2f W", flow.batteryToSystemWatts))
                    .fontWeight(.semibold)
                    .foregroundStyle(EnergyPalette.amberBright)
                    .monospacedDigit()
            }
            .font(.system(size: 11, design: .monospaced))
            
        case .onBattery:
            HStack(spacing: 4) {
                Text("バッテリー消費:")
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(String(format: "-%.2f W", flow.batteryToSystemWatts))
                    .fontWeight(.semibold)
                    .foregroundStyle(EnergyPalette.orangeBright)
                    .monospacedDigit()
            }
            .font(.system(size: 11, design: .monospaced))
            
        case .bypass:
            HStack(spacing: 4) {
                Text("バイパス給電:")
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(String(format: "%.2f W", flow.externalToSystemWatts))
                    .fontWeight(.semibold)
                    .foregroundStyle(EnergyPalette.skyBright)
                    .monospacedDigit()
            }
            .font(.system(size: 11, design: .monospaced))
        }
    }
    
    // MARK: - Telemetry Cards Section
    
    private var telemetryCardsSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                externalPowerCard
                systemLoadCard
            }
            .fixedSize(horizontal: false, vertical: true)
            
            batteryDetailsCard
        }
    }
    
    private var externalPowerCard: some View {
        glassCard {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(info.hasExternalPower ? EnergyPalette.emeraldBright : Color.white.opacity(0.38))
                    Text("外部電源")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                
                VStack(spacing: 5) {
                    metricRow(
                        title: "供給電力",
                        value: String(format: "%.2f W", info.hasExternalPower ? info.adapterPowerWatts : 0.0),
                        valueColor: info.hasExternalPower ? .white : Color.white.opacity(0.45),
                        isEmphasized: true
                    )
                    metricRow(
                        title: "入力電圧",
                        value: String(format: "%.2f V", info.hasExternalPower ? info.adapterVoltageVolts : 0.0),
                        valueColor: info.hasExternalPower ? Color.white.opacity(0.85) : Color.white.opacity(0.45)
                    )
                    metricRow(
                        title: "入力電流",
                        value: String(format: "%.0f mA", info.hasExternalPower ? info.adapterCurrentMilliAmps : 0.0),
                        valueColor: info.hasExternalPower ? Color.white.opacity(0.85) : Color.white.opacity(0.45)
                    )
                    metricRow(
                        title: "アダプタ定格",
                        value: adapterRatingValue,
                        valueColor: info.hasExternalPower ? Color.white.opacity(0.85) : Color.white.opacity(0.45)
                    )
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
    
    private var adapterRatingValue: String {
        guard info.hasExternalPower else { return "未接続" }
        if let watts = info.adapterWatts, watts > 0 {
            return "\(watts) W"
        }
        return "—"
    }
    
    private var systemLoadCard: some View {
        let loadWatts = flow.systemTotalWatts
        let scaleMax = Double(max(info.adapterWatts ?? 100, 100))
        let loadRatio = min(1.0, max(0.03, loadWatts / scaleMax))
        let loadStatus = systemLoadDescription(watts: loadWatts)
        
        return glassCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(EnergyPalette.skyBright)
                    Text("システム消費電力")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text("消費電力")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.55))
                    Spacer()
                    Text(String(format: "%.2f W", loadWatts))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(loadStatus.color)
                        .monospacedDigit()
                }
                .padding(.top, 10)
                
                Spacer(minLength: 10)
                
                Divider()
                    .overlay(Color.white.opacity(0.08))
                    .padding(.bottom, 8)
                
                VStack(spacing: 5) {
                    HStack {
                        Text("負荷レベル")
                            .foregroundStyle(Color.white.opacity(0.5))
                        Spacer()
                        Text(loadStatus.label)
                            .fontWeight(.medium)
                            .foregroundStyle(loadStatus.color)
                            .lineLimit(1)
                    }
                    .font(.system(size: 10))
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.1))
                            
                            Capsule(style: .continuous)
                                .fill(loadStatus.color)
                                .frame(width: max(6, geo.size.width * loadRatio))
                                .animation(.easeInOut(duration: 0.45), value: loadRatio)
                        }
                    }
                    .frame(height: 5)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
    
    private func systemLoadDescription(watts: Double) -> (label: String, color: Color) {
        switch watts {
        case ..<15:
            return ("アイドル / 軽作業", EnergyPalette.skyBright)
        case 15..<35:
            return ("ブラウジング / 通常作業", EnergyPalette.skyBright)
        case 35..<65:
            return ("中負荷作業", EnergyPalette.amberBright)
        default:
            return ("高負荷処理", EnergyPalette.orangeBright)
        }
    }
    
    private var batteryDetailsCard: some View {
        let badge = batteryDirectionBadge
        let powerLabel: String = switch flow.mode {
        case .charging: "充電電力"
        case .batteryAssist, .onBattery: "放電電力"
        case .bypass: "充放電電力"
        }
        let amperageColor: Color = switch flow.mode {
        case .charging: EnergyPalette.emeraldBright
        case .batteryAssist: EnergyPalette.amberBright
        case .onBattery: EnergyPalette.orangeBright
        case .bypass: Color.white.opacity(0.85)
        }
        
        return glassCard {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "battery.100percent")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(badge.color)
                        Text("バッテリー詳細")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    Text(badge.text)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(badge.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(badge.color.opacity(0.16))
                        )
                }
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 6
                ) {
                    metricRow(
                        title: powerLabel,
                        value: String(format: "%.2f W", info.batteryPowerWatts),
                        valueColor: amperageColor,
                        isEmphasized: true
                    )
                    metricRow(
                        title: "セル電圧",
                        value: String(format: "%.2f V", info.batteryVoltageVolts),
                        valueColor: Color.white.opacity(0.88)
                    )
                    metricRow(
                        title: "充放電電流",
                        value: String(format: "%+.0f mA", info.batteryAmperageMilliAmps),
                        valueColor: amperageColor,
                        isEmphasized: true
                    )
                    metricRow(
                        title: "バッテリー健全度",
                        value: info.healthPercentage.map { String(format: "%.1f%%", $0) } ?? "—",
                        valueColor: Color.white.opacity(0.88)
                    )
                    metricRow(
                        title: "充放電回数",
                        value: info.cycleCount.map { "\($0) 回" } ?? "—",
                        valueColor: Color.white.opacity(0.88)
                    )
                    metricRow(
                        title: "バッテリー温度",
                        value: info.temperatureCelsius.map { String(format: "%.1f ℃", $0) } ?? "—",
                        valueColor: Color.white.opacity(0.88)
                    )
                }
            }
        }
    }
    
    private var batteryDirectionBadge: (text: String, color: Color) {
        switch flow.mode {
        case .charging:
            return ("充電中", EnergyPalette.emeraldBright)
        case .batteryAssist:
            return ("放電アシスト", EnergyPalette.amberBright)
        case .onBattery:
            return ("放電中", EnergyPalette.orangeBright)
        case .bypass:
            return (info.isFullyCharged ? "満充電待機" : "充電待機", EnergyPalette.skyBright)
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.white.opacity(0.10))
                .padding(.bottom, 12)
            
            HStack {
                Button {
                    refreshSpinCount += 1
                    onRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .rotationEffect(.degrees(Double(refreshSpinCount) * 360))
                        .animation(.easeInOut(duration: 0.45), value: refreshSpinCount)
                        .frame(width: 30, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(Color.white.opacity(0.11), lineWidth: 0.75)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.white.opacity(0.82))
                .help("手動更新")
                
                Spacer()
                
                HStack(spacing: 8) {
                    SettingsLink {
                        Text("設定…")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Color.white.opacity(0.10))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.75)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("終了")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Color.white.opacity(0.10))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.75)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Reusable Helpers
    
    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            )
    }
    
    private func metricRow(
        title: String,
        value: String,
        valueColor: Color,
        isEmphasized: Bool = false
    ) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: 11, weight: isEmphasized ? .semibold : .medium, design: .monospaced))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
        }
    }
}

// MARK: - Previews

#Preview("充電中") {
    BatteryDetailContentView(
        info: BatteryInfo(
            percentage: 25,
            isCharging: true,
            isPluggedIn: true,
            isFullyCharged: false,
            batteryVoltageVolts: 11.90,
            batteryAmperageMilliAmps: 6523,
            batteryPowerWatts: 77.61,
            cycleCount: 16,
            temperatureCelsius: 31.4,
            healthPercentage: 100.0,
            timeRemainingMinutes: 107,
            hasExternalPower: true,
            adapterWatts: 100,
            adapterVoltageVolts: 19.24,
            adapterCurrentMilliAmps: 4485,
            adapterPowerWatts: 86.29,
            systemLoadWatts: 8.66
        ),
        onRefresh: {}
    )
}

#Preview("高負荷・バッテリー補助") {
    BatteryDetailContentView(
        info: BatteryInfo(
            percentage: 62,
            isCharging: false,
            isPluggedIn: true,
            isFullyCharged: false,
            batteryVoltageVolts: 11.42,
            batteryAmperageMilliAmps: -1611,
            batteryPowerWatts: 18.40,
            cycleCount: 42,
            temperatureCelsius: 36.2,
            healthPercentage: 98.5,
            timeRemainingMinutes: 252,
            hasExternalPower: true,
            adapterWatts: 100,
            adapterVoltageVolts: 19.85,
            adapterCurrentMilliAmps: 4866,
            adapterPowerWatts: 96.60,
            systemLoadWatts: 115.00
        ),
        onRefresh: {}
    )
}

#Preview("バッテリー駆動") {
    BatteryDetailContentView(
        info: BatteryInfo(
            percentage: 78,
            isCharging: false,
            isPluggedIn: false,
            isFullyCharged: false,
            batteryVoltageVolts: 11.68,
            batteryAmperageMilliAmps: -1584,
            batteryPowerWatts: 18.50,
            cycleCount: 42,
            temperatureCelsius: 29.8,
            healthPercentage: 98.5,
            timeRemainingMinutes: 385,
            hasExternalPower: false,
            adapterWatts: nil,
            adapterVoltageVolts: 0,
            adapterCurrentMilliAmps: 0,
            adapterPowerWatts: 0,
            systemLoadWatts: 18.50
        ),
        onRefresh: {}
    )
}

#Preview("満充電バイパス") {
    BatteryDetailContentView(
        info: BatteryInfo(
            percentage: 100,
            isCharging: false,
            isPluggedIn: true,
            isFullyCharged: true,
            batteryVoltageVolts: 12.58,
            batteryAmperageMilliAmps: 0,
            batteryPowerWatts: 0,
            cycleCount: 16,
            temperatureCelsius: 28.0,
            healthPercentage: 100.0,
            timeRemainingMinutes: nil,
            hasExternalPower: true,
            adapterWatts: 100,
            adapterVoltageVolts: 20.02,
            adapterCurrentMilliAmps: 759,
            adapterPowerWatts: 15.20,
            systemLoadWatts: 15.20
        ),
        onRefresh: {}
    )
}
