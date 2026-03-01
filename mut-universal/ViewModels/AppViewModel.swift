import Observation
import Foundation

@Observable
final class AppViewModel {
    var currentScreen: AppScreen = .login
    var isAuthenticated = false

    /// The API client, injected at app launch.
    var apiClient: (any JamfProAPIClientProtocol)?

    func navigateTo(_ screen: AppScreen) {
        currentScreen = screen
    }

    func logout() async {
        try? await apiClient?.invalidateToken()
        isAuthenticated = false
        currentScreen = .login
    }
}
