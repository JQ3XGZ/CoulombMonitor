//
//  LaunchAtLoginService.swift
//  CoulombMonitor
//

import Foundation
import ServiceManagement
import OSLog

private let logger = Logger(subsystem: "local.rd753.CoulombMonitor", category: "LaunchAtLogin")

@MainActor
@Observable
final class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()
    
    var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            updateRegistration(enabled: isEnabled)
        }
    }
    
    private init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    func refreshStatus() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    private func updateRegistration(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                    logger.info("Successfully registered launch at login")
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    logger.info("Successfully unregistered launch at login")
                }
            }
        } catch {
            logger.error("Failed to update launch at login status: \(error.localizedDescription)")
            // Revert state if registration failed
            self.isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
}
