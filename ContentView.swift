import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var proc: ProcessManager
    @EnvironmentObject var game: GameManager
    @State private var tab: Tab = .library
    @State private var showImporter = false
    @State private var lastPressed = ""
    @State private var conflictURL: URL?
    @State private var showConflict = false
    
    enum Tab: Hashable { case library, keypad, console, settings }
    
    @ViewBuilder
    var sidebar: some View {
        List {
            Section {
                Button { tab = .library } label: {
                    Label("tab_library", systemImage: "square.grid.2x2.fill")
                }
                Button { tab = .keypad } label: {
                    Label("tab_emulator", systemImage: "gamecontroller.fill")
                }
            }
            Section {
                Button { tab = .console } label: {
                    Label("tab_console", systemImage: "terminal.fill")
                }
                Button { tab = .settings } label: {
                    Label("tab_settings", systemImage: "gearshape.fill")
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("app_title")
    }
    
    var detail: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch tab {
            case .library:
                GameLibraryView { item in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        proc.start(game: item.path)
                        tab = .keypad
                    }
                }
            case .console:
                ConsoleView()
            case .keypad:
                VStack(spacing: 16) {
                    if let cg = proc.currentGamePath {
                        WebEmulatorView(gamePath: cg, lastPressed: lastPressed)
                            .background(Color.black)
                            .cornerRadius(Theme.radius)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .padding()
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "gamecontroller")
                                .font(.system(size: 56))
                                .foregroundColor(Theme.subText)
                            Text("emulator_no_game")
                                .font(Theme.text(16, weight: .medium))
                                .foregroundColor(Theme.subText)
                        }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    KeypadView(lastPressed: $lastPressed).padding(.horizontal).padding(.bottom)
                }
            case .settings:
                SettingsView()
            }
        }
    }
    
    var body: some View {
        ZStack {
            Group {
                if #available(iOS 16.0, *) {
                    NavigationSplitView {
                        sidebar
                    } detail: {
                        detail
                    }
                } else {
                    NavigationView {
                        sidebar
                        detail
                    }
                    .navigationViewStyle(DoubleColumnNavigationViewStyle())
                }
            }
            .navigationTitle(Text(tab == .library ? "tab_library" : tab == .keypad ? "tab_emulator" : tab == .console ? "tab_console" : "tab_settings"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if tab == .library {
                        Button { showImporter = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [UTType(filenameExtension: "jar") ?? .data]
            ) { res in
                if case .success(let url) = res {
                    if game.checkDuplicate(filename: url.lastPathComponent) {
                        conflictURL = url
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showConflict = true }
                    } else {
                        withAnimation { game.importGame(url: url, overwrite: false) }
                        Haptics.success()
                    }
                }
            }
            
            if showConflict {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showConflict = false }
                        conflictURL = nil
                    }
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.danger)
                    
                    Text("conflict_title").font(Theme.text(20, weight: .bold))
                    Text("conflict_desc").font(Theme.text(15)).foregroundColor(Theme.subText).multilineTextAlignment(.center)
                    Text("conflict_warning").font(Theme.text(13, weight: .medium)).foregroundColor(Theme.danger)
                    
                    VStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showConflict = false }
                            if let url = conflictURL { game.importGame(url: url, overwrite: true) }
                            conflictURL = nil
                            Haptics.success()
                        } label: {
                            Text("conflict_overwrite")
                                .font(Theme.text(16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.danger)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showConflict = false }
                            if let url = conflictURL { game.importGame(url: url, overwrite: false) }
                            conflictURL = nil
                            Haptics.success()
                        } label: {
                            Text("conflict_rename")
                                .font(Theme.text(16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showConflict = false }
                            conflictURL = nil
                        } label: {
                            Text("conflict_cancel")
                                .font(Theme.text(16, weight: .semibold))
                                .foregroundColor(Theme.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.bg)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(24)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .padding(32)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
    }
}
