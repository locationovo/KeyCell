import SwiftUI
import WebKit

final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    let resourceDirectory: URL
    let gamePath: String?
    private let lock = NSLock()
    private var activeTasks = Set<ObjectIdentifier>()
    
    init(resourceDirectory: URL, gamePath: String?) {
        self.resourceDirectory = resourceDirectory
        self.gamePath = gamePath
    }
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        lock.lock()
        activeTasks.insert(ObjectIdentifier(urlSchemeTask))
        lock.unlock()
        handle(urlSchemeTask, url: url)
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        lock.lock()
        activeTasks.remove(ObjectIdentifier(urlSchemeTask))
        lock.unlock()
    }
    
    private func isTaskActive(_ task: WKURLSchemeTask) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return activeTasks.contains(ObjectIdentifier(task))
    }
    
    private func handle(_ task: WKURLSchemeTask, url: URL) {
        if url.path == "/game.jar" {
            handleJar(task, url: url)
        } else {
            handleResource(task, url: url)
        }
    }
    
    private func handleJar(_ task: WKURLSchemeTask, url: URL) {
        guard let gamePath = gamePath else {
            finish(task, error: NSError(domain: "KeyCell", code: 404))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let fileHandle = FileHandle(forReadingAtPath: gamePath) else {
                DispatchQueue.main.async { self.finish(task, error: NSError(domain: "KeyCell", code: 404)) }
                return
            }
            defer { try? fileHandle.close() }
            
            let fileAttributes = try? FileManager.default.attributesOfItem(atPath: gamePath)
            let fileSize = (fileAttributes?[.size] as? UInt64) ?? 0
            
            let headers = [
                "Content-Type": "application/java-archive",
                "Content-Length": "\(fileSize)",
                "Access-Control-Allow-Origin": "*"
            ]
            
            guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) else {
                DispatchQueue.main.async { self.finish(task, error: NSError(domain: "KeyCell", code: 500)) }
                return
            }
            
            DispatchQueue.main.async {
                if self.isTaskActive(task) { task.didReceive(response) }
            }
            
            while true {
                if !self.isTaskActive(task) { break }
                let data = fileHandle.readData(ofLength: 128 * 1024)
                if data.isEmpty { break }
                DispatchQueue.main.async {
                    if self.isTaskActive(task) { task.didReceive(data) }
                }
                Thread.sleep(forTimeInterval: 0.002)
            }
            
            DispatchQueue.main.async {
                self.finish(task, error: nil)
            }
        }
    }
    
    private func handleResource(_ task: WKURLSchemeTask, url: URL) {
        var relative = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        relative = relative.removingPercentEncoding ?? relative
        let fileURL = resourceDirectory.appendingPathComponent(relative).standardizedFileURL
        
        DispatchQueue.global(qos: .userInitiated).async {
            var data: Data
            let mime = self.mimeType(for: fileURL.pathExtension)
            
            if let fileData = try? Data(contentsOf: fileURL) {
                data = fileData
            } else {
                data = "throw new Error('File not found: /\(relative)');".data(using: .utf8)!
            }
            
            let headers = [
                "Content-Type": mime,
                "Content-Length": "\(data.count)",
                "Access-Control-Allow-Origin": "*"
            ]
            
            guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) else {
                DispatchQueue.main.async { self.finish(task, error: NSError(domain: "KeyCell", code: 500)) }
                return
            }
            
            DispatchQueue.main.async {
                if self.isTaskActive(task) {
                    task.didReceive(response)
                    task.didReceive(data)
                }
                self.finish(task, error: nil)
            }
        }
    }
    
    private func finish(_ task: WKURLSchemeTask, error: Error?) {
        lock.lock()
        let id = ObjectIdentifier(task)
        guard activeTasks.contains(id) else {
            lock.unlock()
            return
        }
        activeTasks.remove(id)
        lock.unlock()
        
        if let error = error {
            task.didFailWithError(error)
        } else {
            task.didFinish()
        }
    }
    
    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html": return "text/html; charset=utf-8"
        case "js", "mjs": return "text/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "wasm": return "application/wasm"
        case "jar": return "application/java-archive"
        default: return "application/octet-stream"
        }
    }
}

struct WebEmulatorView: UIViewRepresentable {
    let gamePath: String
    let lastPressed: String
    @EnvironmentObject var proc: ProcessManager
    @EnvironmentObject var settings: SettingsManager
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let distURL = Bundle.main.bundleURL.appendingPathComponent("dist")
        config.setURLSchemeHandler(LocalSchemeHandler(resourceDirectory: distURL, gamePath: gamePath), forURLScheme: "keycell")
        
        let ucc = WKUserContentController()
        ucc.add(context.coordinator, name: "log")
        
        let script = """
        window.global = window;
        window.process = { env: { NODE_ENV: 'production' }, platform: 'browser' };
        console.log = function(msg) { window.webkit.messageHandlers.log.postMessage(JSON.stringify({ type: "log", msg: String(msg) })); };
        console.error = function(msg) { window.webkit.messageHandlers.log.postMessage(JSON.stringify({ type: "error", msg: String(msg) })); };
        window.onerror = function(msg, url, line) { window.webkit.messageHandlers.log.postMessage(JSON.stringify({ type: "error", msg: msg + "(Line:" + line + ")" })); return false; };
        """
        ucc.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        
        // 注入文件路径列表
        let listScript = generateFileListScript(baseURL: distURL)
        ucc.addUserScript(WKUserScript(source: listScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        
        config.userContentController = ucc
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.layer.cornerRadius = Theme.radius
        webView.layer.masksToBounds = true
        
        if let entryURL = URL(string: "keycell://local/index.html") { webView.load(URLRequest(url: entryURL)) }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self
        if lastPressed.isEmpty { context.coordinator.lastInjected = nil; return }
        guard context.coordinator.lastInjected != lastPressed else { return }
        context.coordinator.lastInjected = lastPressed
        let data = (try? JSONSerialization.data(withJSONObject: [lastPressed])) ?? Data()
        let arr = String(data: data, encoding: .utf8) ?? "[\"\"]"
        let payload = String(arr.dropFirst().dropLast())
        uiView.evaluateJavaScript("window.onKeyPress && window.onKeyPress(\(payload));") { _, _ in }
    }
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "log")
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    private func generateFileListScript(baseURL: URL) -> String {
        let srcURL = baseURL.appendingPathComponent("src")
        var files: [String] = []
        
        if let enumerator = FileManager.default.enumerator(at: srcURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "js" {
                    let relative = fileURL.path.replacingOccurrences(of: srcURL.path, with: "/src/")
                    files.append(relative)
                }
            }
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: files),
           let jsonStr = String(data: data, encoding: .utf8) {
            return "window.J2MEFilesList = \(jsonStr);"
        }
        return "window.J2MEFilesList = [];"
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebEmulatorView
        var lastInjected: String?
        init(_ parent: WebEmulatorView) { self.parent = parent }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("window.setResolution && window.setResolution(\(parent.settings.displayWidth), \(parent.settings.displayHeight));", completionHandler: nil)
            webView.evaluateJavaScript("window.bootGame && window.bootGame();", completionHandler: nil)
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "log", let jsonStr = message.body as? String, let data = jsonStr.data(using: .utf8), let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let msg = dict["msg"] as? String {
                let isError = (dict["type"] as? String == "error")
                Task { @MainActor in self.parent.proc.appendLog("[JS]\(msg)", isError: isError) }
            }
        }
    }
}
