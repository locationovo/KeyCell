import SwiftUI

struct ConsoleView: View {
    @EnvironmentObject var proc: ProcessManager
    @State private var showShare = false
    @State private var shareURL: URL?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(proc.logs) { log in
                        HStack(alignment: .top, spacing: 12) {
                            Text(log.time, style: .time)
                                .font(Theme.mono(12))
                                .foregroundColor(Theme.subText)
                                .padding(.top, 2)
                            Text(log.text)
                                .font(Theme.mono(13))
                                .foregroundColor(log.isError ? Theme.danger : Theme.text)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(log.isError ? Theme.danger.opacity(0.1) : Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .padding(.horizontal)
                        .id(log.id)
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.bg)
            .onChange(of: proc.logs.count) { _ in
                if let last = proc.logs.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    proc.copyLogs()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                
                Button {
                    if let url = proc.exportLogs() {
                        shareURL = url
                        showShare = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
