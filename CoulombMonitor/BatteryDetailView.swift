//
//  BatteryDetailView.swift
//  CoulombMonitor
//

import SwiftUI

struct BatteryDetailView: View {
    let monitor: BatteryMonitor
    
    var body: some View {
        VStack(spacing: 14) {
            // Header: Battery Level and Status
            headerSection
            
            Divider()
            
            // Section 1: 外部電源 (接続時のみ表示)
            if monitor.info.hasExternalPower {
                externalPowerSection
                Divider()
            }
            
            // Section 2: バッテリー
            batterySection
            
            Divider()
            
            // Section 3: システム消費電力
            systemPowerSection
            
            Divider()
            
            // Footer: Manual refresh, Settings, Quit
            footerSection
        }
        .padding(16)
        .frame(width: 320)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(monitor.info.percentage)%")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: monitor.info.hasExternalPower ? (monitor.info.isCharging ? "bolt.fill" : "powerplug.fill") : "battery.100percent")
                        .foregroundStyle(monitor.info.isCharging ? .green : .secondary)
                    Text(monitor.info.stateDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            ProgressView(value: Double(monitor.info.percentage), total: 100.0)
                .tint(progressTint)
            
            if let timeRemaining = monitor.info.timeRemainingFormatted {
                HStack {
                    Text(monitor.info.isCharging ? "満充電まで:" : "残り時間:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(timeRemaining)
                        .font(.caption.weight(.semibold))
                    Spacer()
                }
            }
        }
    }
    
    private var progressTint: Color {
        if monitor.info.isCharging {
            return .green
        } else if monitor.info.percentage <= 20 {
            return .red
        } else {
            return .accentColor
        }
    }
    
    // MARK: - Category: 外部電源
    
    private var externalPowerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "外部電源", icon: "powerplug.fill")
            
            metricRow(
                icon: "bolt.badge.clock",
                title: "供給電力",
                value: String(format: "%.2f W", monitor.info.adapterPowerWatts)
            )
            metricRow(
                icon: "waveform.path.ecg",
                title: "入力電圧",
                value: String(format: "%.2f V", monitor.info.adapterVoltageVolts)
            )
            metricRow(
                icon: "arrow.down.forward",
                title: "入力電流",
                value: String(format: "%.0f mA", monitor.info.adapterCurrentMilliAmps)
            )
            if let ratedWatts = monitor.info.adapterWatts, ratedWatts > 0 {
                metricRow(
                    icon: "speedometer",
                    title: "アダプタ定格",
                    value: "\(ratedWatts) W"
                )
            }
        }
    }
    
    // MARK: - Category: バッテリー
    
    private var batterySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "バッテリー", icon: "battery.100percent")
            
            metricRow(
                icon: "bolt.circle",
                title: monitor.info.isCharging ? "充電電力" : "充放電電力",
                value: String(format: "%.2f W", monitor.info.batteryPowerWatts)
            )
            metricRow(
                icon: "waveform.path.ecg",
                title: "セル電圧",
                value: String(format: "%.2f V", monitor.info.batteryVoltageVolts)
            )
            metricRow(
                icon: "arrow.left.arrow.right",
                title: "充放電電流",
                value: String(format: "%+.0f mA", monitor.info.batteryAmperageMilliAmps)
            )
            
            if let health = monitor.info.healthPercentage {
                metricRow(
                    icon: "heart.fill",
                    title: "バッテリー健全度",
                    value: String(format: "%.1f%%", health)
                )
            }
            if let cycles = monitor.info.cycleCount {
                metricRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "充放電回数",
                    value: "\(cycles) 回"
                )
            }
            if let temp = monitor.info.temperatureCelsius {
                metricRow(
                    icon: "thermometer.medium",
                    title: "バッテリー温度",
                    value: String(format: "%.1f ℃", temp)
                )
            }
        }
    }
    
    // MARK: - Category: システム消費電力
    
    private var systemPowerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "システム消費電力", icon: "cpu")
            
            metricRow(
                icon: "bolt.fill",
                title: "消費電力",
                value: String(format: "%.2f W", monitor.info.systemLoadWatts)
            )
        }
    }
    
    // MARK: - Reusable Row Components
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.secondary)
        .padding(.bottom, 2)
    }
    
    private func metricRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack {
            Button {
                monitor.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("手動更新")
            
            Spacer()
            
            SettingsLink {
                Text("設定…")
            }
            
            Button("終了") {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.callout)
    }
}
