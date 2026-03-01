import SwiftUI

struct RootView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
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
    }
}
