import SwiftUI
import UIKit

struct LogEntry: Identifiable {
    let id = UUID()
    let time = Date()
    let text: String
    let isError: Bool
}

@MainActor
class ProcessManager: ObservableObject {
    @Published var running = false
    @Published var currentGamePath: String? = nil
    @Published var logs: [LogEntry] = [LogEntry(text: NSLocalizedString("emulator_init", comment: ""), isError: false)]
    
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    
    func start(game: String) {
        running = true
        currentGamePath = game
        appendLog("\(NSLocalizedString("log_mounted", comment: "")):\(URL(fileURLWithPath: game).lastPathComponent)")
    }
    
    func stop() {
        running = false
        currentGamePath = nil
        appendLog(NSLocalizedString("log_terminated", comment: ""))
    }
    
    func appendLog(_ text: String, isError: Bool = false) {
        let entry = LogEntry(text: text, isError: isError)
        self.logs.append(entry)
        if self.logs.count > 500 {
            self.logs.removeFirst()
        }
    }
    
    func exportLogs() -> URL? {
        let text = logs.map { "[\(formatter.string(from: $0.time))] \($0.text)" }.joined(separator: "\n")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("KeyCell_Logs.txt")
        do {
            try text.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }
    
    func copyLogs() {
        let text = logs.map { "[\(formatter.string(from: $0.time))] \($0.text)" }.joined(separator: "\n")
        UIPasteboard.general.string = text
        Haptics.success()
    }
}
