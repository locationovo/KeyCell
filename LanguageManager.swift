import SwiftUI
class LanguageManager: ObservableObject {
    @AppStorage("app_language") var lang: String = "system"
    var locale: Locale {
        switch lang {
        case "zh": return Locale(identifier: "zh-Hans")
        case "en": return Locale(identifier: "en")
        default: return Locale.current
        }
    }
}
