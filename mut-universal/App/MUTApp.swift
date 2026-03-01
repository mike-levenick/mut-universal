import SwiftUI

@main
struct MUTApp: App {
    @State private var appViewModel: AppViewModel
    @State private var logStore: LogStore

    init() {
        let vm = AppViewModel()
        vm.apiClient = JamfProAPIService()
        _appViewModel = State(initialValue: vm)

        let store = LogStore()
        _logStore = State(initialValue: store)
        MUTLogger.configure(buffer: store.buffer) {
            Task { @MainActor in
                store.sync()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appViewModel)
                .environment(logStore)
        }
    }
}
