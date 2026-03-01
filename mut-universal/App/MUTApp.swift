import SwiftUI

@main
struct MUTApp: App {
    @State private var appViewModel: AppViewModel

    init() {
        let vm = AppViewModel()
        vm.apiClient = JamfProAPIService()
        _appViewModel = State(initialValue: vm)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appViewModel)
        }
    }
}
