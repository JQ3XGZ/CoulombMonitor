//
//  BatteryMonitor.swift
//  CoulombMonitor
//

import Foundation
import IOKit
import IOKit.ps
import IOKit.pwr_mgt

@MainActor
@Observable
final class BatteryMonitor {
    var info: BatteryInfo = BatteryInfo()
    var isAvailable: Bool = true
    
    @ObservationIgnored
    private var timerTask: Task<Void, Never>?
    
    @ObservationIgnored
    private var updateInterval: TimeInterval = 2.0
    
    init(updateInterval: TimeInterval = 2.0) {
        self.updateInterval = updateInterval
        refresh()
        startMonitoring()
    }
    
    deinit {
        timerTask?.cancel()
    }
    
    func startMonitoring() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64((self?.updateInterval ?? 2.0) * 1_000_000_000))
                if Task.isCancelled { break }
                self?.refresh()
            }
        }
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        self.updateInterval = max(1.0, interval)
        startMonitoring()
    }
    
    func refresh() {
        if let smartBatteryInfo = fetchAppleSmartBatteryInfo() {
            self.info = smartBatteryInfo
            self.isAvailable = true
        } else if let fallbackInfo = fetchPowerSourcesInfoFallback() {
            self.info = fallbackInfo
            self.isAvailable = true
        } else {
            self.isAvailable = false
        }
    }
    
    // MARK: - IOKit AppleSmartBattery
    
    private func fetchAppleSmartBatteryInfo() -> BatteryInfo? {
        let matchingDict = IOServiceMatching("AppleSmartBattery")
        var iterator: io_iterator_t = 0
        
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        guard result == kIOReturnSuccess else { return nil }
        defer { IOObjectRelease(iterator) }
        
        let service = IOIteratorNext(iterator)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        
        var propsUnmanaged: Unmanaged<CFMutableDictionary>?
        let kr = IORegistryEntryCreateCFProperties(service, &propsUnmanaged, kCFAllocatorDefault, 0)
        guard kr == kIOReturnSuccess, let properties = propsUnmanaged?.takeRetainedValue() as? [String: Any] else {
            return nil
        }
        
        let batteryData = properties["BatteryData"] as? [String: Any]
        let powerTelemetry = properties["PowerTelemetryData"] as? [String: Any]
        let adapterDetails = properties["AdapterDetails"] as? [String: Any]
        
        // MARK: 1. Battery Capacities & State
        let currentCapacity = (batteryData?["CurrentCapacity"] as? Int) ?? (properties["CurrentCapacity"] as? Int ?? 0)
        let maxCapacity = (batteryData?["MaxCapacity"] as? Int) ?? (properties["MaxCapacity"] as? Int ?? 100)
        let designCapacity = (batteryData?["DesignCapacity"] as? Int) ?? (properties["DesignCapacity"] as? Int)
        let cycleCount = properties["CycleCount"] as? Int
        
        let isCharging = properties["IsCharging"] as? Bool ?? false
        let isFullyCharged = properties["FullyCharged"] as? Bool ?? false
        let isPluggedIn = properties["ExternalConnected"] as? Bool ?? (properties["ExternalChargeCapable"] as? Bool ?? false)
        
        // MARK: 2. Battery Electric Metrics (セル自体の電気)
        let batteryVoltageMV = (properties["Voltage"] as? NSNumber)?.doubleValue ?? 0.0
        let batteryVoltageVolts = batteryVoltageMV / 1000.0
        
        var batteryAmperageMA = (properties["InstantAmperage"] as? NSNumber)?.doubleValue
        if batteryAmperageMA == nil || batteryAmperageMA == 0 {
            batteryAmperageMA = (properties["Amperage"] as? NSNumber)?.doubleValue ?? 0.0
        }
        let batteryAmperageVal = batteryAmperageMA ?? 0.0
        let batteryPowerWatts = abs(batteryVoltageMV * batteryAmperageVal) / 1_000_000.0
        
        // MARK: 3. External Power Metrics (外部電源)
        let hasExternalPower = isPluggedIn
        let adapterWatts = adapterDetails?["Watts"] as? Int
        
        var adapterVoltageVolts = 0.0
        var adapterCurrentMilliAmps = 0.0
        var adapterPowerWatts = 0.0
        
        if hasExternalPower {
            if let telemetry = powerTelemetry {
                let vInMV = (telemetry["SystemVoltageIn"] as? NSNumber)?.doubleValue ?? 0.0
                adapterVoltageVolts = vInMV / 1000.0
                adapterCurrentMilliAmps = (telemetry["SystemCurrentIn"] as? NSNumber)?.doubleValue ?? 0.0
                let pInMW = (telemetry["SystemPowerIn"] as? NSNumber)?.doubleValue ?? 0.0
                adapterPowerWatts = pInMW / 1000.0
            }
            
            // Fallback from AdapterDetails if telemetry is not present
            if adapterVoltageVolts == 0.0, let nominalV = adapterDetails?["AdapterVoltage"] as? NSNumber {
                adapterVoltageVolts = nominalV.doubleValue / 1000.0
            }
            if adapterPowerWatts == 0.0, adapterVoltageVolts > 0.0 && adapterCurrentMilliAmps > 0.0 {
                adapterPowerWatts = (adapterVoltageVolts * adapterCurrentMilliAmps) / 1000.0
            }
        }
        
        // MARK: 4. System Consumption (システム消費電力)
        var systemLoadWatts = 0.0
        if let telemetry = powerTelemetry {
            let loadMW = (telemetry["SystemLoad"] as? NSNumber)?.doubleValue ?? 0.0
            if loadMW > 0 {
                systemLoadWatts = loadMW / 1000.0
            }
        }
        
        if systemLoadWatts == 0.0 {
            if hasExternalPower {
                // System load is adapter power minus charging power, or plus discharging assist power
                let signedBatteryWatts = batteryAmperageVal >= 0 ? batteryPowerWatts : -batteryPowerWatts
                systemLoadWatts = max(0.0, adapterPowerWatts - signedBatteryWatts)
            } else {
                systemLoadWatts = batteryPowerWatts
            }
        }
        
        // MARK: 5. Battery Diagnostics (温度・健全度・残り時間)
        let temperatureCelsius = extractTemperatureCelsius(from: properties)
            ?? fetchTemperatureFromChildren(of: service)
        
        var healthPercentage: Double? = nil
        let rawMax = (batteryData?["AppleRawMaxCapacity"] as? Int) ?? (batteryData?["FullChargeCapacity"] as? Int)
        if let design = designCapacity, design > 0, let maxCap = rawMax, maxCap > 0 {
            healthPercentage = min(100.0, (Double(maxCap) / Double(design)) * 100.0)
        } else if let design = designCapacity, design > 0, maxCapacity > 0 {
            healthPercentage = min(100.0, (Double(maxCapacity) / Double(design)) * 100.0)
        }
        
        let percentage = maxCapacity > 0 ? Int((Double(currentCapacity) / Double(maxCapacity)) * 100.0) : 0
        
        var timeRemaining: Int? = nil
        if isCharging {
            if let avgToFull = properties["AvgTimeToFull"] as? Int, avgToFull > 0 && avgToFull < 65535 {
                timeRemaining = avgToFull
            }
        } else {
            if let avgToEmpty = properties["AvgTimeToEmpty"] as? Int, avgToEmpty > 0 && avgToEmpty < 65535 {
                timeRemaining = avgToEmpty
            }
        }
        
        return BatteryInfo(
            percentage: min(100, max(0, percentage)),
            isCharging: isCharging,
            isPluggedIn: isPluggedIn,
            isFullyCharged: isFullyCharged,
            batteryVoltageVolts: batteryVoltageVolts,
            batteryAmperageMilliAmps: batteryAmperageVal,
            batteryPowerWatts: batteryPowerWatts,
            cycleCount: cycleCount,
            temperatureCelsius: temperatureCelsius,
            healthPercentage: healthPercentage,
            timeRemainingMinutes: timeRemaining,
            hasExternalPower: hasExternalPower,
            adapterWatts: adapterWatts,
            adapterVoltageVolts: adapterVoltageVolts,
            adapterCurrentMilliAmps: adapterCurrentMilliAmps,
            adapterPowerWatts: adapterPowerWatts,
            systemLoadWatts: systemLoadWatts
        )
    }
    
    private func fetchTemperatureFromChildren(of parent: io_registry_entry_t) -> Double? {
        var childIterator: io_iterator_t = 0
        guard IORegistryEntryGetChildIterator(parent, kIOServicePlane, &childIterator) == kIOReturnSuccess else {
            return nil
        }
        defer { IOObjectRelease(childIterator) }
        
        while case let child = IOIteratorNext(childIterator), child != 0 {
            defer { IOObjectRelease(child) }
            var propsUnmanaged: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(child, &propsUnmanaged, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                  let childProps = propsUnmanaged?.takeRetainedValue() as? [String: Any] else {
                continue
            }
            if let temp = extractTemperatureCelsius(from: childProps) {
                return temp
            }
        }
        return nil
    }
    
    private func extractTemperatureCelsius(from properties: [String: Any]) -> Double? {
        let batteryData = properties["BatteryData"] as? [String: Any]
        let rawTemp = (properties["Temperature"] as? NSNumber)?.doubleValue
            ?? (batteryData?["Temperature"] as? NSNumber)?.doubleValue
            ?? (batteryData?["VirtualTemperature"] as? NSNumber)?.doubleValue
        
        guard let rawTemp else { return nil }
        return Self.parseTemperatureCelsius(rawTemp)
    }
    
    nonisolated static func parseTemperatureCelsius(_ rawTemp: Double) -> Double? {
        guard rawTemp > 0 else { return nil }
        if rawTemp >= 500 {
            return rawTemp / 100.0
        } else if rawTemp > 100 {
            return rawTemp / 10.0
        } else {
            return rawTemp
        }
    }
    
    // MARK: - IOPowerSources Fallback
    
    private func fetchPowerSourcesInfoFallback() -> BatteryInfo? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef], !sources.isEmpty else {
            return nil
        }
        
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            let curCap = description[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maxCap = description[kIOPSMaxCapacityKey] as? Int ?? 100
            let isCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false
            let isCharged = (description[kIOPSIsChargedKey] as? Bool) ?? false
            let powerSourceState = description[kIOPSPowerSourceStateKey] as? String
            let isPluggedIn = powerSourceState == kIOPSACPowerValue
            let timeToEmpty = description[kIOPSTimeToEmptyKey] as? Int
            let timeToFull = description[kIOPSTimeToFullChargeKey] as? Int
            
            let percent = maxCap > 0 ? Int((Double(curCap) / Double(maxCap)) * 100.0) : 0
            let timeRemaining = isCharging ? (timeToFull != -1 ? timeToFull : nil) : (timeToEmpty != -1 ? timeToEmpty : nil)
            
            return BatteryInfo(
                percentage: percent,
                isCharging: isCharging,
                isPluggedIn: isPluggedIn,
                isFullyCharged: isCharged,
                batteryVoltageVolts: 0.0,
                batteryAmperageMilliAmps: 0.0,
                batteryPowerWatts: 0.0,
                cycleCount: nil,
                temperatureCelsius: nil,
                healthPercentage: nil,
                timeRemainingMinutes: timeRemaining,
                hasExternalPower: isPluggedIn,
                adapterWatts: nil,
                adapterVoltageVolts: 0.0,
                adapterCurrentMilliAmps: 0.0,
                adapterPowerWatts: 0.0,
                systemLoadWatts: 0.0
            )
        }
        return nil
    }
}
