import Observation
import Foundation

@Observable
final class AppViewModel {
    var currentScreen: AppScreen = .login
    var isAuthenticated = false

    var apiClient: (any JamfProAPIClientProtocol)?

    var csvData: CSVData?
    var selectedDeviceType: DeviceType = .macOS
    var columnMapping: [Int: UpdatableField] = [:]
    var updateOperations: [UpdateOperation] = []

    func navigateTo(_ screen: AppScreen) {
        currentScreen = screen
    }

    func logout() async {
        try? await apiClient?.invalidateToken()
        isAuthenticated = false
        csvData = nil
        columnMapping = [:]
        updateOperations = []
        currentScreen = .login
    }

    func startOver() {
        csvData = nil
        columnMapping = [:]
        updateOperations = []
        currentScreen = .csvImport
    }
}
