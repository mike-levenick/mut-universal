import SwiftUI

struct RootView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(LogStore.self) private var logStore
    @State private var showLogViewer = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            switch appViewModel.currentScreen {
            case .login:
                LoginView()
            case .csvImport:
                CSVImportView()
            case .csvPreview:
                CSVPreviewView()
            case .updateProgress:
                UpdateProgressView()
            case .updateResults:
                UpdateResultsView()
            }

            Button {
                showLogViewer.toggle()
            } label: {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title3)
                    .padding(10)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding()
            .help("View Logs")
            .keyboardShortcut("L", modifiers: [.command, .option])
        }
        .sheet(isPresented: $showLogViewer) {
            LogViewerView()
        }
    }
}
