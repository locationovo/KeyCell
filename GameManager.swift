import Foundation
@MainActor
class GameManager: ObservableObject {
    @Published var list: [Item] = []
    private var gamesDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("games")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    struct Item: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let path: String
        let size: String
    }
    init() { Task { await load() } }
    func load() async {
        let currentDir = gamesDirectory
        let items = await Task.detached(priority: .userInitiated) {
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: currentDir.path) else { return [Item]() }
            return files.filter { $0.hasSuffix(".jar") }.compactMap { f -> Item? in
                let p = currentDir.appendingPathComponent(f).path
                guard let a = try? FileManager.default.attributesOfItem(atPath: p), let s = a[.size] as? UInt64 else { return nil }
                return Item(name: f, path: p, size: ByteCountFormatter.string(fromByteCount: Int64(s), countStyle: .file))
            }
        }.value
        self.list = items
    }
    func checkDuplicate(filename: String) -> Bool {
        let dest = gamesDirectory.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: dest.path)
    }
    func importGame(url: URL, overwrite: Bool) {
        let currentDir = gamesDirectory
        Task.detached(priority: .userInitiated) {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            var dest = currentDir.appendingPathComponent(url.lastPathComponent)
            if overwrite {
                try? FileManager.default.removeItem(at: dest)
            } else {
                let base = url.deletingPathExtension().lastPathComponent
                let ext = url.pathExtension
                var counter = 1
                while FileManager.default.fileExists(atPath: dest.path) {
                    dest = currentDir.appendingPathComponent("\(base)_\(counter).\(ext)")
                    counter += 1
                }
            }
            try? FileManager.default.copyItem(at: url, to: dest)
            await self.load()
        }
    }
    func remove(_ item: Item) {
        Task.detached(priority: .userInitiated) {
            try? FileManager.default.removeItem(atPath: item.path)
            await self.load()
        }
    }
}
