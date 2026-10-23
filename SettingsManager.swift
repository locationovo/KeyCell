import SwiftUI
class SettingsManager: ObservableObject {
    struct Resolution: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let width: Int
        let height: Int
    }
    let availableResolutions = [
        Resolution(name: "240x320", width: 240, height: 320),
        Resolution(name: "176x220", width: 176, height: 220),
        Resolution(name: "128x160", width: 128, height: 160)
    ]
    @AppStorage("display_width") var displayWidth: Int = 240
    @AppStorage("display_height") var displayHeight: Int = 320
    var currentResolutionString: String { "\(displayWidth)x\(displayHeight)" }
}
