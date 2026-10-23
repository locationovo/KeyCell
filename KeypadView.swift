import SwiftUI
struct KeypadView: View {
    @Binding var lastPressed: String
    private let keys: [(String, String)] = [
        ("UP", "arrowtriangle.up.fill"), ("DOWN", "arrowtriangle.down.fill"),
        ("LEFT", "arrowtriangle.left.fill"), ("RIGHT", "arrowtriangle.right.fill"),
        ("FIRE", "circle.circle.fill")
    ]
    @State private var pressedKey: String? = nil
    @State private var pressTask: Task<Void, Never>? = nil
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("keypad_title").font(Theme.text(15, weight: .medium)).foregroundColor(Theme.subText)
                Spacer()
                Text(lastPressed.isEmpty ? NSLocalizedString("keypad_none", comment: "") : lastPressed)
                    .font(Theme.mono(15, weight: .bold)).foregroundColor(Theme.accent)
            }
            HStack(spacing: 16) {
                ForEach(keys, id: \.0) { id, icon in
                    Button { trigger(id) } label: {
                        Image(systemName: icon).font(.system(size: 22))
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(pressedKey == id ? Theme.accent : Theme.card)
                            .foregroundColor(pressedKey == id ? .white : Theme.text)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                            .shadow(color: pressedKey == id ? Theme.accent.opacity(0.3) : .black.opacity(0.05), radius: 8, x: 0, y: 4)
                            .scaleEffect(pressedKey == id ? 0.92 : 1.0)
                    }.buttonStyle(.plain)
                }
            }
        }.padding(.horizontal).onDisappear { pressTask?.cancel() }
    }
    private func trigger(_ key: String) {
        Haptics.impact(.light)
        pressTask?.cancel()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { pressedKey = key; lastPressed = key }
        pressTask = Task {
            do {
                try await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        pressedKey = nil; if lastPressed == key { lastPressed = "" }
                    }
                }
            } catch {}
        }
    }
}
