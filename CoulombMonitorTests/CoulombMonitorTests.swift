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
}
