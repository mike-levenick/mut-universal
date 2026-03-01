import SwiftUI

/// The root view that switches between app screens based on navigation state.
struct RootView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        switch appViewModel.currentScreen {
        case .login:
            Text("Login Screen")
        case .csvImport:
            Text("CSV Import")
        case .csvPreview:
            Text("CSV Preview")
        case .updateProgress:
            Text("Update Progress")
        case .updateResults:
            Text("Update Results")
        }
    }
}
