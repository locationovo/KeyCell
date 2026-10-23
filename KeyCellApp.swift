import SwiftUI

@main
struct KeyCellApp: App {
    @StateObject private var lang = LanguageManager()
    @StateObject private var game = GameManager()
    @StateObject private var proc = ProcessManager()
    @StateObject private var settings = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(lang)
                .environmentObject(game)
                .environmentObject(proc)
                .environmentObject(settings)
                .environment(\.locale, lang.locale)
        }
    }
}
