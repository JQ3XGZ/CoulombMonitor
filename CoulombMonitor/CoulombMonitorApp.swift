//
//  CoulombMonitorApp.swift
//  CoulombMonitor
//

import SwiftUI

@main
struct CoulombMonitorApp: App {
    @State private var monitor = BatteryMonitor()
    @State private var settings = AppSettings.shared
    
    var body: some Scene {
        MenuBarExtra {
            BatteryDetailView(monitor: monitor)
        } label: {
            MenuBarTitleView(info: monitor.info, settings: settings)
        }
        .menuBarExtraStyle(.window)
        .onChange(of: settings.updateInterval) { _, newValue in
            monitor.setUpdateInterval(newValue)
        }
        
        Settings {
            SettingsView()
        }
    }
}
