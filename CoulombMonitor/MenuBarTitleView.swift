//
//  MenuBarTitleView.swift
//  CoulombMonitor
//

import SwiftUI

struct MenuBarTitleView: View {
    let info: BatteryInfo
    let settings: AppSettings
    
    var body: some View {
        let icon = settings.currentIcon(for: info)
        
        switch icon {
        case .emoji(let emoji):
            // When icon is an emoji, combining with titleText as a single Text view
            // prevents macOS MenuBarExtra from stripping or failing to render adjacent Text elements.
            if !titleText.isEmpty {
                Text("\(emoji)  \(titleText)")
                    .monospacedDigit()
            } else {
                Text(emoji)
            }
            
        case .sfSymbol, .asset:
            HStack(spacing: 4) {
                IconImageView(
                    icon: icon,
                    color: .primary,
                    size: 16
                )
                
                if !titleText.isEmpty {
                    Text(titleText)
                        .monospacedDigit()
                }
            }
        }
    }
    
    var titleText: String {
        var parts: [String] = []
        if settings.showPercentage {
            parts.append("\(info.percentage)%")
        }
        if settings.showPowerWatts {
            parts.append(formattedWatts)
        }
        return parts.joined(separator: "  ")
    }
    
    private var formattedWatts: String {
        let places = settings.wattDecimalPlaces
        let formatString = "%.\(places)fW"
        return String(format: formatString, info.displayPowerWatts)
    }
}

/// Helper view to render SF Symbol, Asset image, or Emoji
struct IconImageView: View {
    let icon: IconImage
    var color: Color = .primary
    var size: CGFloat = 16
    
    var body: some View {
        switch icon {
        case .sfSymbol(let name):
            Image(systemName: name)
                .font(.system(size: size))
                .foregroundStyle(color)
        case .asset(let name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(color)
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size))
        }
    }
}
