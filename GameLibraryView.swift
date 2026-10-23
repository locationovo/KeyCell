import SwiftUI

struct GameLibraryView: View {
    @EnvironmentObject var game: GameManager
    var onLaunch: (GameManager.Item) -> Void
    
    var body: some View {
        Group {
            if game.list.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray").font(.system(size: 56)).foregroundColor(Theme.subText)
                    Text("library_empty_title").font(Theme.text(20, weight: .semibold))
                    Text("library_empty_subtitle").font(Theme.text(14)).foregroundColor(Theme.subText)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(game.list) { item in
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.accent.opacity(0.15)).frame(width: 48, height: 48)
                                Image(systemName: "gamecontroller.fill").font(.system(size: 24)).foregroundColor(Theme.accent)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name).font(Theme.text(16, weight: .medium))
                                Text(item.size).font(Theme.text(13)).foregroundColor(Theme.subText)
                            }
                            Spacer()
                            Button { Haptics.impact(.medium); onLaunch(item) } label: {
                                Text("btn_launch").font(Theme.text(15, weight: .semibold)).padding(.horizontal, 20).padding(.vertical, 8)
                                    .background(Theme.accent).foregroundColor(.white).clipShape(Capsule())
                            }.buttonStyle(.plain)
                        }.padding(.vertical, 6).listRowBackground(Theme.card)
                    }.onDelete { idx in
                        let snapshot = game.list
                        withAnimation { for i in idx.reversed() { game.remove(snapshot[i]) } }
                        Haptics.success()
                    }
                }.listStyle(InsetGroupedListStyle())
            }
        }
    }
}
