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
}
