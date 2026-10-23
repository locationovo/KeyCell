import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var settings: SettingsManager
    var body: some View {
        Form {
            Section {
                Picker("settings_resolution", selection: Binding(
                    get: { settings.currentResolutionString },
                    set: { newVal in
                        let parts = newVal.split(separator: "x")
                        if parts.count == 2, let w = Int(parts[0]), let h = Int(parts[1]) {
                            settings.displayWidth = w; settings.displayHeight = h
                        }
                    }
                )) {
                    ForEach(settings.availableResolutions) { res in Text(res.name).tag("\(res.width)x\(res.height)") }
                }
            } header: { Text("settings_display") }
            Section {
                Picker("settings_language", selection: $lang.lang) {
                    Text("settings_language_system").tag("system")
                    Text("settings_language_zh").tag("zh")
                    Text("settings_language_en").tag("en")
                }
            } header: { Text("settings_language") }
        }.background(Theme.bg)
    }
}
