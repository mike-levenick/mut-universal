import Observation
import Foundation

@Observable
final class UpdateProgressViewModel {
    var totalOperations: Int = 0
    var completedOperations: Int = 0
    var results: [UpdateResult] = []
    var isRunning: Bool = false

    var progress: Double {
        guard totalOperations > 0 else { return 0 }
        return Double(completedOperations) / Double(totalOperations)
    }

    var successCount: Int {
        results.filter {
            if case .success = $0.status { true } else { false }
        }.count
    }

    var failureCount: Int {
        results.filter {
            if case .failed = $0.status { true } else { false }
        }.count
    }

    func runUpdates(
        operations: [UpdateOperation],
        deviceType: DeviceType,
        apiClient: any JamfProAPIClientProtocol
    ) async {
        isRunning = true
        totalOperations = operations.count
        completedOperations = 0
        results = []

        let engine = UpdateEngine(apiClient: apiClient)
        let allResults = await engine.execute(
            operations: operations,
            deviceType: deviceType,
            onProgress: { [weak self] completed, total, result in
                Task { @MainActor in
                    self?.completedOperations = completed
                    self?.results.append(result)
                }
            }
        )

        results = allResults
        isRunning = false
    }
}
