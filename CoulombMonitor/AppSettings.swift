//
//  AppSettings.swift
//  CoulombMonitor
//

import Foundation
import SwiftUI

/// Defines the icon source type: either SF Symbol, Emoji, or custom SVG asset.
enum IconImage: Equatable, Sendable {
    case sfSymbol(String)
    case asset(String)
    case emoji(String)
}

/// Represents the major icon collection / theme
nonisolated enum BatteryIconCollection: String, CaseIterable, Identifiable, Sendable {
    case sfSymbols = "macOS 標準 (SF Symbols)"
    case emoji = "絵文字 (Emoji)"
    case solarBold = "Solar (Bold)"
    case solarOutline = "Solar (Outline)"
    case solarBrokenLine = "Solar (Broken Line)"
    case iconcino = "Iconcino"
    case genericaTiny = "Generica (Tiny)"
    
    var id: String { rawValue }
    
    var supportsSubOptions: Bool {
        switch self {
        case .solarBold, .solarOutline, .solarBrokenLine:
            return true
        default:
            return false
        }
    }
    
    var licenseAttribution: (text: String, url: String)? {
        switch self {
        case .solarBold:
            return ("Solar Bold Icons by 480 Design (CC BY 4.0)", "https://www.svgrepo.com/collection/solar-bold-icons/")
        case .solarOutline:
            return ("Solar Outline Icons by 480 Design (CC BY 4.0)", "https://www.svgrepo.com/collection/solar-outline-icons/")
        case .solarBrokenLine:
            return ("Solar Broken Line Icons by 480 Design (CC BY 4.0)", "https://www.svgrepo.com/collection/solar-broken-line-icons/")
        case .genericaTiny:
            return ("Generica Tiny Icons by Generica (CC BY 4.0)", "https://www.svgrepo.com/collection/generica-tiny-interface-icons/")
        case .iconcino:
            return ("Iconcino Interface Icons (Public Domain)", "https://www.svgrepo.com/collection/iconcino-interface-icons/")
        case .sfSymbols, .emoji:
            return nil
        }
    }
}

/// Charging icon style variant for Solar icons
nonisolated enum SolarChargeStyle: String, CaseIterable, Identifiable, Sendable {
    case standard = "標準 (Battery Charge)"
    case minimalistic = "ミニマル (Minimalistic)"
    case station = "スタンド (Refueling Station)"
    
    var id: String { rawValue }
}

/// Battery style variant for Solar icons
nonisolated enum SolarBatteryStyle: String, CaseIterable, Identifiable, Sendable {
    case standard = "標準"
    case minimalistic = "ミニマル"
    
    var id: String { rawValue }
}

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    var collection: BatteryIconCollection {
        didSet { defaults.set(collection.rawValue, forKey: "iconCollection") }
    }
    
    var solarChargeStyle: SolarChargeStyle {
        didSet { defaults.set(solarChargeStyle.rawValue, forKey: "solarChargeStyle") }
    }
    
    var solarBatteryStyle: SolarBatteryStyle {
        didSet { defaults.set(solarBatteryStyle.rawValue, forKey: "solarBatteryStyle") }
    }
    
    var showPercentage: Bool {
        didSet { defaults.set(showPercentage, forKey: "showPercentage") }
    }
    
    var showPowerWatts: Bool {
        didSet { defaults.set(showPowerWatts, forKey: "showPowerWatts") }
    }
    
    var wattDecimalPlaces: Int {
        didSet { defaults.set(wattDecimalPlaces, forKey: "wattDecimalPlaces") }
    }
    
    var updateInterval: Double {
        didSet { defaults.set(updateInterval, forKey: "updateInterval") }
    }
    
    private init() {
        defaults.register(defaults: [
            "iconCollection": BatteryIconCollection.sfSymbols.rawValue,
            "solarChargeStyle": SolarChargeStyle.standard.rawValue,
            "solarBatteryStyle": SolarBatteryStyle.standard.rawValue,
            "showPercentage": true,
            "showPowerWatts": true,
            "wattDecimalPlaces": 1,
            "updateInterval": 2.0
        ])
        
        let savedCollection = defaults.string(forKey: "iconCollection") ?? ""
        self.collection = BatteryIconCollection(rawValue: savedCollection) ?? .sfSymbols
        
        let savedChargeStyle = defaults.string(forKey: "solarChargeStyle") ?? ""
        self.solarChargeStyle = SolarChargeStyle(rawValue: savedChargeStyle) ?? .standard
        
        let savedBatteryStyle = defaults.string(forKey: "solarBatteryStyle") ?? ""
        self.solarBatteryStyle = SolarBatteryStyle(rawValue: savedBatteryStyle) ?? .standard
        
        self.showPercentage = defaults.bool(forKey: "showPercentage")
        self.showPowerWatts = defaults.bool(forKey: "showPowerWatts")
        self.wattDecimalPlaces = defaults.integer(forKey: "wattDecimalPlaces")
        self.updateInterval = defaults.double(forKey: "updateInterval")
    }
    
    /// Resolves the icon image based on current power state and battery info.
    func currentIcon(for info: BatteryInfo) -> IconImage {
        if info.hasExternalPower {
            if info.isCharging {
                return chargingIcon
            } else {
                return pluggedIcon
            }
        } else {
            return batteryIcon(for: info)
        }
    }
    
    var chargingIcon: IconImage {
        switch collection {
        case .sfSymbols:
            return .sfSymbol("bolt.fill")
        case .emoji:
            return .emoji("⚡️")
        case .solarBold:
            switch solarChargeStyle {
            case .standard: return .asset("solar-bold-battery-charge")
            case .minimalistic: return .asset("solar-bold-battery-charge-minimalistic")
            case .station: return .asset("solar-bold-electric-refueling")
            }
        case .solarOutline:
            switch solarChargeStyle {
            case .standard: return .asset("solar-outline-battery-charge")
            case .minimalistic: return .asset("solar-outline-battery-charge-minimalistic")
            case .station: return .asset("solar-outline-electric-refueling")
            }
        case .solarBrokenLine:
            switch solarChargeStyle {
            case .standard: return .asset("solar-broken-line-battery-charge")
            case .minimalistic: return .asset("solar-broken-line-battery-charge-minimalistic")
            case .station: return .asset("solar-broken-line-electric-refueling")
            }
        case .iconcino:
            return .asset("iconcino-battery-charging-1")
        case .genericaTiny:
            return .asset("generica-tiny-battery-charging")
        }
    }
    
    var pluggedIcon: IconImage {
        switch collection {
        case .sfSymbols:
            return .sfSymbol("powerplug.fill")
        case .emoji:
            return .emoji("🔌")
        case .solarBold:
            return .asset("solar-bold-plug-circle")
        case .solarOutline:
            return .asset("solar-outline-plug-circle")
        case .solarBrokenLine:
            return .asset("solar-broken-line-plug-circle")
        case .iconcino:
            return .asset("iconcino-plug")
        case .genericaTiny:
            return .asset("generica-tiny-bulb-2")
        }
    }
    
    func batteryIcon(for info: BatteryInfo) -> IconImage {
        let level = min(100, max(0, info.percentage))
        
        switch collection {
        case .sfSymbols:
            if level >= 88 { return .sfSymbol("battery.100percent") }
            else if level >= 63 { return .sfSymbol("battery.75percent") }
            else if level >= 38 { return .sfSymbol("battery.50percent") }
            else if level >= 13 { return .sfSymbol("battery.25percent") }
            else { return .sfSymbol("battery.0percent") }
            
        case .emoji:
            if level <= 20 {
                return .emoji("🪫")
            } else {
                return .emoji("🔋")
            }
            
        case .solarBold:
            let isMinimal = solarBatteryStyle == .minimalistic
            if level > 60 {
                return .asset(isMinimal ? "solar-bold-battery-full-minimalistic" : "solar-bold-battery-full")
            } else if level > 25 {
                return .asset(isMinimal ? "solar-bold-battery-half-minimalistic" : "solar-bold-battery-half")
            } else {
                return .asset(isMinimal ? "solar-bold-battery-low-minimalistic" : "solar-bold-battery-low")
            }
            
        case .solarOutline:
            let isMinimal = solarBatteryStyle == .minimalistic
            if level > 60 {
                return .asset(isMinimal ? "solar-outline-battery-full-minimalistic" : "solar-outline-battery-full")
            } else if level > 25 {
                return .asset(isMinimal ? "solar-outline-battery-half-minimalistic" : "solar-outline-battery-half")
            } else {
                return .asset(isMinimal ? "solar-outline-battery-low-minimalistic" : "solar-outline-battery-low")
            }
            
        case .solarBrokenLine:
            let isMinimal = solarBatteryStyle == .minimalistic
            if level > 60 {
                return .asset(isMinimal ? "solar-broken-line-battery-full-minimalistic" : "solar-broken-line-battery-full")
            } else if level > 25 {
                return .asset(isMinimal ? "solar-broken-line-battery-half-minimalistic" : "solar-broken-line-battery-half")
            } else {
                return .asset(isMinimal ? "solar-broken-line-battery-low-minimalistic" : "solar-broken-line-battery-low")
            }
            
        case .iconcino:
            if level > 75 {
                return .asset("iconcino-battery-full")
            } else if level > 30 {
                return .asset("iconcino-battery-mid")
            } else if level > 5 {
                return .asset("iconcino-battery-low")
            } else {
                return .asset("iconcino-battery-empty")
            }
            
        case .genericaTiny:
            if level > 75 {
                return .asset("generica-tiny-battery-3")
            } else if level > 40 {
                return .asset("generica-tiny-battery-2")
            } else if level > 15 {
                return .asset("generica-tiny-battery-1")
            } else {
                return .asset("generica-tiny-battery")
            }
        }
    }
    
    var previewIcons: (charging: IconImage, plugged: IconImage, batteryFull: IconImage, batteryMid: IconImage, batteryLow: IconImage) {
        let fullInfo = BatteryInfo(percentage: 100, isCharging: false, hasExternalPower: false)
        let midInfo = BatteryInfo(percentage: 50, isCharging: false, hasExternalPower: false)
        let lowInfo = BatteryInfo(percentage: 15, isCharging: false, hasExternalPower: false)
        return (chargingIcon, pluggedIcon, batteryIcon(for: fullInfo), batteryIcon(for: midInfo), batteryIcon(for: lowInfo))
    }
}
