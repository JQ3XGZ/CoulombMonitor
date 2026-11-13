//
//  SettingsView.swift
//  CoulombMonitor
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings = AppSettings.shared
    @Bindable var launchAtLogin: LaunchAtLoginService = LaunchAtLoginService.shared
    
    var body: some View {
        Form {
            Section("アイコンテーマ") {
                Picker("コレクション", selection: $settings.collection) {
                    ForEach(BatteryIconCollection.allCases) { collection in
                        Text(collection.rawValue).tag(collection)
                    }
                }
                
                if settings.collection.supportsSubOptions {
                    Picker("充電アイコン", selection: $settings.solarChargeStyle) {
                        ForEach(SolarChargeStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    
                    Picker("バッテリー形状", selection: $settings.solarBatteryStyle) {
                        ForEach(SolarBatteryStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("プレビュー")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    let preview = settings.previewIcons
                    HStack(spacing: 12) {
                        previewItem(title: "充電中", icon: preview.charging)
                        previewItem(title: "給電中", icon: preview.plugged)
                        previewItem(title: "100%", icon: preview.batteryFull)
                        previewItem(title: "50%", icon: preview.batteryMid)
                        previewItem(title: "15%", icon: preview.batteryLow)
                    }
                }
                .padding(.vertical, 2)
            }
            
            Section("メニューバー文字表示") {
                Toggle("残量 (%) を表示", isOn: $settings.showPercentage)
                
                Toggle("電力 (W) を表示", isOn: $settings.showPowerWatts)
                
                if settings.showPowerWatts {
                    Picker("電力の小数点桁数", selection: $settings.wattDecimalPlaces) {
                        Text("なし (例: 14W)").tag(0)
                        Text("1桁 (例: 14.2W)").tag(1)
                        Text("2桁 (例: 14.25W)").tag(2)
                    }
                }
            }
            
            Section("一般") {
                Toggle("ログイン時に自動起動", isOn: $launchAtLogin.isEnabled)
                
                Picker("更新頻度", selection: $settings.updateInterval) {
                    Text("1 秒").tag(1.0)
                    Text("2 秒 (推奨)").tag(2.0)
                    Text("5 秒").tag(5.0)
                }
            }
            
            if let attribution = settings.collection.licenseAttribution {
                Section("ライセンス・クレジット") {
                    VStack(alignment: .leading, spacing: 4) {
                        if let url = URL(string: attribution.url) {
                            Link(attribution.text, destination: url)
                                .font(.caption)
                        } else {
                            Text(attribution.text)
                                .font(.caption)
                        }
                    }
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    Button("アプリを終了", role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 440)
        .navigationTitle("設定")
    }
    
    @ViewBuilder
    private func previewItem(title: String, icon: IconImage) -> some View {
        VStack(spacing: 4) {
            IconImageView(icon: icon, color: .primary, size: 18)
                .frame(width: 22, height: 22)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
