//
//  CoulombMonitorTests.swift
//  CoulombMonitorTests
//

import Testing
@testable import CoulombMonitor

@Suite @MainActor
struct CoulombMonitorTests {
    @Test func testBatteryInfoCalculations() async throws {
        let info = BatteryInfo(
            percentage: 85,
            isCharging: true,
            isPluggedIn: true,
            isFullyCharged: false,
            batteryVoltageVolts: 11.4,
            batteryAmperageMilliAmps: 1500.0,
            batteryPowerWatts: 17.1,
            cycleCount: 42,
            temperatureCelsius: 29.5,
            healthPercentage: 98.0,
            timeRemainingMinutes: 75,
            hasExternalPower: true,
            adapterWatts: 100,
            adapterVoltageVolts: 20.0,
            adapterCurrentMilliAmps: 1200.0,
            adapterPowerWatts: 24.0,
            systemLoadWatts: 6.9
        )
        
        #expect(info.percentage == 85)
        #expect(info.isCharging == true)
        #expect(info.displayPowerWatts == 24.0)
        #expect(info.batteryPowerWatts == 17.1)
        #expect(info.timeRemainingFormatted == "1時間15分")
        #expect(info.stateDescription.contains("充電中"))
    }
    
    @Test func testIconCollectionsAndEmoji() async throws {
        let settings = AppSettings.shared
        
        // Emoji Collection
        settings.collection = .emoji
        let chargingInfo = BatteryInfo(percentage: 80, isCharging: true, hasExternalPower: true)
        #expect(settings.currentIcon(for: chargingInfo) == .emoji("⚡️"))
        
        let pluggedInfo = BatteryInfo(percentage: 100, isCharging: false, hasExternalPower: true)
        #expect(settings.currentIcon(for: pluggedInfo) == .emoji("🔌"))
        
        let batteryNormalInfo = BatteryInfo(percentage: 50, isCharging: false, hasExternalPower: false)
        #expect(settings.currentIcon(for: batteryNormalInfo) == .emoji("🔋"))
        
        let batteryLowInfo = BatteryInfo(percentage: 10, isCharging: false, hasExternalPower: false)
        #expect(settings.currentIcon(for: batteryLowInfo) == .emoji("🪫"))
    }
    
    @Test func testAllCollectionsResolveIcons() async throws {
        let settings = AppSettings.shared
        let chargingInfo = BatteryInfo(percentage: 80, isCharging: true, hasExternalPower: true)
        let pluggedInfo = BatteryInfo(percentage: 100, isCharging: false, hasExternalPower: true)
        let batteryInfo = BatteryInfo(percentage: 50, isCharging: false, hasExternalPower: false)
        
        for collection in BatteryIconCollection.allCases {
            settings.collection = collection
            _ = settings.currentIcon(for: chargingInfo)
            _ = settings.currentIcon(for: pluggedInfo)
            _ = settings.currentIcon(for: batteryInfo)
            
            let preview = settings.previewIcons
            #expect(preview.charging != preview.plugged || collection == .sfSymbols)
        }
    }
    
    @Test func testMenuBarTitleTextWithExternalPower() async throws {
        let info = BatteryInfo(
            percentage: 85,
            hasExternalPower: true,
            adapterPowerWatts: 24.0
        )
        let settings = AppSettings.shared
        settings.showPercentage = true
        settings.showPowerWatts = true
        settings.wattDecimalPlaces = 1
        
        let titleView = MenuBarTitleView(info: info, settings: settings)
        #expect(titleView.titleText == "85%  24.0W")
    }
    
    @Test func testMenuBarTitleTextOnBattery() async throws {
        let info = BatteryInfo(
            percentage: 75,
            batteryPowerWatts: 12.5,
            hasExternalPower: false
        )
        let settings = AppSettings.shared
        settings.showPercentage = true
        settings.showPowerWatts = true
        settings.wattDecimalPlaces = 1
        
        let titleView = MenuBarTitleView(info: info, settings: settings)
        #expect(titleView.titleText == "75%  12.5W")
    }
    
    @Test func testEnergyFlowChargingMode() async throws {
        let info = BatteryInfo(
            percentage: 25,
            isCharging: true,
            isPluggedIn: true,
            batteryAmperageMilliAmps: 6523,
            batteryPowerWatts: 77.61,
            hasExternalPower: true,
            adapterWatts: 100,
            adapterPowerWatts: 86.29,
            systemLoadWatts: 8.66
        )
        let flow = info.energyFlow
        #expect(flow.mode == .charging)
        #expect(flow.externalTotalWatts == 86.29)
        #expect(flow.externalToBatteryWatts == 77.61)
        #expect(flow.externalToSystemWatts == 8.66)
        #expect(flow.batteryToSystemWatts == 0.0)
        #expect(flow.systemTotalWatts == 8.66)
        #expect(flow.batteryNetWatts == 77.61)
    }
    
    @Test func testEnergyFlowBatteryAssistMode() async throws {
        let info = BatteryInfo(
            percentage: 62,
            isCharging: false,
            isPluggedIn: true,
            batteryAmperageMilliAmps: -1611,
            batteryPowerWatts: 18.40,
            hasExternalPower: true,
            adapterWatts: 100,
            adapterPowerWatts: 96.60,
            systemLoadWatts: 115.00
        )
        let flow = info.energyFlow
        #expect(flow.mode == .batteryAssist)
        #expect(flow.externalTotalWatts == 96.60)
        #expect(flow.externalToBatteryWatts == 0.0)
        #expect(flow.externalToSystemWatts == 96.60)
        #expect(flow.batteryToSystemWatts == 18.40)
        #expect(flow.systemTotalWatts == 115.00)
        #expect(flow.batteryNetWatts == -18.40)
    }
    
    @Test func testEnergyFlowOnBatteryMode() async throws {
        let info = BatteryInfo(
            percentage: 78,
            isCharging: false,
            isPluggedIn: false,
            batteryAmperageMilliAmps: -1584,
            batteryPowerWatts: 18.50,
            hasExternalPower: false,
            systemLoadWatts: 18.50
        )
        let flow = info.energyFlow
        #expect(flow.mode == .onBattery)
        #expect(flow.externalTotalWatts == 0.0)
        #expect(flow.externalToBatteryWatts == 0.0)
        #expect(flow.externalToSystemWatts == 0.0)
        #expect(flow.batteryToSystemWatts == 18.50)
        #expect(flow.systemTotalWatts == 18.50)
        #expect(flow.batteryNetWatts == -18.50)
    }
    
    @Test func testEnergyFlowBypassMode() async throws {
        let info = BatteryInfo(
            percentage: 100,
            isCharging: false,
            isPluggedIn: true,
            isFullyCharged: true,
            batteryAmperageMilliAmps: 0,
            batteryPowerWatts: 0,
            hasExternalPower: true,
            adapterWatts: 100,
            adapterPowerWatts: 15.20,
            systemLoadWatts: 15.20
        )
        let flow = info.energyFlow
        #expect(flow.mode == .bypass)
        #expect(flow.externalTotalWatts == 15.20)
        #expect(flow.externalToBatteryWatts == 0.0)
        #expect(flow.externalToSystemWatts == 15.20)
        #expect(flow.batteryToSystemWatts == 0.0)
        #expect(flow.systemTotalWatts == 15.20)
        #expect(flow.batteryNetWatts == 0.0)
    }
    
    @Test func testParseTemperatureCelsius() async throws {
        #expect(BatteryMonitor.parseTemperatureCelsius(3359) == 33.59)
        #expect(BatteryMonitor.parseTemperatureCelsius(2950) == 29.50)
        #expect(BatteryMonitor.parseTemperatureCelsius(335) == 33.5)
        #expect(BatteryMonitor.parseTemperatureCelsius(0) == nil)
    }
    
    @Test @MainActor func testBatteryMonitorReadsTemperatureWhenBatteryPresent() async throws {
        let monitor = BatteryMonitor(updateInterval: 60.0)
        if monitor.isAvailable && monitor.info.batteryVoltageVolts > 0 {
            #expect(monitor.info.temperatureCelsius != nil)
            if let temp = monitor.info.temperatureCelsius {
                #expect(temp > 0 && temp < 100)
            }
        }
    }
}
