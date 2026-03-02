import Foundation
import OSLog

/// Orchestrates batch update operations with concurrency limiting and progress tracking.
actor UpdateEngine {
    private let apiClient: any JamfProAPIClientProtocol
    private let maxConcurrency = 1

    init(apiClient: any JamfProAPIClientProtocol) {
        self.apiClient = apiClient
    }

    /// Execute all update operations with concurrency limiting.
    func execute(
        operations: [UpdateOperation],
        deviceType: DeviceType,
        onProgress: (@Sendable (Int, Int, UpdateResult) -> Void)?
    ) async -> [UpdateResult] {
        var results: [UpdateResult] = []
        results.reserveCapacity(operations.count)

        await withTaskGroup(of: UpdateResult.self) { group in
            var inFlight = 0
            var index = 0

            while index < operations.count || inFlight > 0 {
                while inFlight < maxConcurrency && index < operations.count {
                    let operation = operations[index]
                    group.addTask {
                        await self.executeOne(operation, deviceType: deviceType)
                    }
                    inFlight += 1
                    index += 1
                }

                if let result = await group.next() {
                    results.append(result)
                    inFlight -= 1
                    onProgress?(results.count, operations.count, result)
                }
            }
        }

        Logger.updates.info("Batch complete: \(results.count) operations processed")
        return results
    }

    private func executeOne(
        _ operation: UpdateOperation,
        deviceType: DeviceType
    ) async -> UpdateResult {
        do {
            let deviceID: String
            switch deviceType {
            case .macOS:
                deviceID = try await apiClient.lookupComputer(bySerial: operation.identifier)
            case .iOS:
                deviceID = try await apiClient.lookupMobileDevice(bySerial: operation.identifier)
            }

            switch deviceType {
            case .macOS:
                try await apiClient.updateComputerInventory(id: deviceID, fields: operation.fieldUpdates)
            case .iOS:
                try await apiClient.updateMobileDeviceInventory(id: deviceID, fields: operation.fieldUpdates)
            }

            return UpdateResult(
                id: operation.id,
                identifier: operation.identifier,
                status: .success,
                timestamp: Date.now
            )
        } catch {
            Logger.updates.error("Update failed for \(operation.identifier): \(error.localizedDescription)")
            return UpdateResult(
                id: operation.id,
                identifier: operation.identifier,
                status: .failed(error: error.localizedDescription),
                timestamp: Date.now
            )
        }
    }
}
