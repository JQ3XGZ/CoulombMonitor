//
//  BatteryInfo.swift
//  CoulombMonitor
//

import Foundation

nonisolated struct BatteryInfo: Sendable, Equatable {
    // MARK: - Battery Metrics
    var percentage: Int = 0
    var isCharging: Bool = false
    var isPluggedIn: Bool = false
    var isFullyCharged: Bool = false
    
    var batteryVoltageVolts: Double = 0.0          // V
    var batteryAmperageMilliAmps: Double = 0.0     // mA (positive: charging, negative: discharging)
    var batteryPowerWatts: Double = 0.0            // W (|V * A| / 1000)
    
    var cycleCount: Int?
    var temperatureCelsius: Double?
    var healthPercentage: Double?                  // Maximum capacity / Design capacity * 100
    var timeRemainingMinutes: Int?                 // Time remaining to full or empty
    
    // MARK: - External Power Metrics (外部電源)
    var hasExternalPower: Bool = false
    var adapterWatts: Int?                         // Nominal rating (e.g. 100W)
    var adapterVoltageVolts: Double = 0.0          // V
    var adapterCurrentMilliAmps: Double = 0.0      // mA
    var adapterPowerWatts: Double = 0.0            // W
    
    // MARK: - System Consumption (システム消費電力)
    var systemLoadWatts: Double = 0.0              // W
    
    // MARK: - Computed Properties for Menu Bar Display
    var displayPowerWatts: Double {
        if hasExternalPower {
            return adapterPowerWatts
        } else {
            return batteryPowerWatts
        }
    }
    
    var stateDescription: String {
        if isFullyCharged && isPluggedIn {
            return "満充電 (給電中)"
        } else if isCharging {
            return "充電中 (\(String(format: "%.1f", displayPowerWatts)) W)"
        } else if isPluggedIn {
            return "外部電源接続中 (給電のみ)"
        } else {
            return "バッテリー駆動中 (\(String(format: "%.1f", displayPowerWatts)) W)"
        }
    }
    
    var timeRemainingFormatted: String? {
        guard let minutes = timeRemainingMinutes, minutes > 0 else { return nil }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)時間\(remainingMinutes)分"
        } else {
            return "\(remainingMinutes)分"
        }
    }
    
    // MARK: - Energy Flow Snapshot
    
    var energyFlow: EnergyFlowSnapshot {
        EnergyFlowSnapshot(info: self)
    }
}

nonisolated enum EnergyFlowMode: Sendable, Equatable {
    case charging
    case batteryAssist
    case onBattery
    case bypass
}

nonisolated struct EnergyFlowSnapshot: Sendable, Equatable {
    let mode: EnergyFlowMode
    let externalTotalWatts: Double
    let externalToBatteryWatts: Double
    let externalToSystemWatts: Double
    let batteryToSystemWatts: Double
    let systemTotalWatts: Double
    let batteryNetWatts: Double
    
    init(info: BatteryInfo) {
        if !info.hasExternalPower {
            self.mode = .onBattery
            let dischargeWatts = info.batteryPowerWatts > 0 ? info.batteryPowerWatts : info.systemLoadWatts
            self.externalTotalWatts = 0.0
            self.externalToBatteryWatts = 0.0
            self.externalToSystemWatts = 0.0
            self.batteryToSystemWatts = dischargeWatts
            self.systemTotalWatts = info.systemLoadWatts > 0 ? info.systemLoadWatts : dischargeWatts
            self.batteryNetWatts = -dischargeWatts
        } else if info.isCharging || info.batteryAmperageMilliAmps > 50 {
            self.mode = .charging
            let chargeWatts = info.batteryPowerWatts
            let totalExternal = info.adapterPowerWatts > 0
                ? info.adapterPowerWatts
                : (chargeWatts + info.systemLoadWatts)
            let sysWatts = info.systemLoadWatts > 0
                ? info.systemLoadWatts
                : max(0.0, totalExternal - chargeWatts)
            self.externalTotalWatts = totalExternal
            self.externalToBatteryWatts = chargeWatts
            self.externalToSystemWatts = sysWatts
            self.batteryToSystemWatts = 0.0
            self.systemTotalWatts = sysWatts
            self.batteryNetWatts = chargeWatts
        } else if info.batteryAmperageMilliAmps < -50 && info.batteryPowerWatts >= 0.5 {
            self.mode = .batteryAssist
            let assistWatts = info.batteryPowerWatts
            let extWatts = info.adapterPowerWatts
            self.externalTotalWatts = extWatts
            self.externalToBatteryWatts = 0.0
            self.externalToSystemWatts = extWatts
            self.batteryToSystemWatts = assistWatts
            self.systemTotalWatts = info.systemLoadWatts > 0
                ? info.systemLoadWatts
                : (extWatts + assistWatts)
            self.batteryNetWatts = -assistWatts
        } else {
            self.mode = .bypass
            let extWatts = info.adapterPowerWatts
            let sysWatts = info.systemLoadWatts > 0 ? info.systemLoadWatts : extWatts
            self.externalTotalWatts = extWatts
            self.externalToBatteryWatts = 0.0
            self.externalToSystemWatts = sysWatts
            self.batteryToSystemWatts = 0.0
            self.systemTotalWatts = sysWatts
            self.batteryNetWatts = 0.0
        }
    }
}
