import Testing
@testable import mut_universal
import Foundation

struct UpdateEngineTests {
    @Test func executesAllOperations() async {
        let mock = MockJamfProAPIClient()
        mock.lookupComputerResults = ["SERIAL1": "1", "SERIAL2": "2"]
        let engine = UpdateEngine(apiClient: mock)

        let operations = [
            UpdateOperation(id: UUID(), identifier: "SERIAL1", fieldUpdates: [
                .init(field: .assetTag, value: "ASSET-001"),
            ]),
            UpdateOperation(id: UUID(), identifier: "SERIAL2", fieldUpdates: [
                .init(field: .assetTag, value: "ASSET-002"),
            ]),
        ]

        let results = await engine.execute(
            operations: operations,
            deviceType: .macOS,
            onProgress: nil
        )

        #expect(results.count == 2)
        #expect(results.allSatisfy {
            if case .success = $0.status { true } else { false }
        })
    }

    @Test func handlesLookupFailure() async {
        let mock = MockJamfProAPIClient()
        // No results configured — lookups will throw
        let engine = UpdateEngine(apiClient: mock)

        let operations = [
            UpdateOperation(id: UUID(), identifier: "UNKNOWN", fieldUpdates: [
                .init(field: .assetTag, value: "ASSET-001"),
            ]),
        ]

        let results = await engine.execute(
            operations: operations,
            deviceType: .macOS,
            onProgress: nil
        )

        #expect(results.count == 1)
        if case .failed = results[0].status {
            // Expected
        } else {
            Issue.record("Expected failed status")
        }
    }

    @Test func separatesDeviceNameForClassicAPI() async {
        let mock = MockJamfProAPIClient()
        mock.lookupMobileDeviceResults = ["SERIAL1": "1"]
        let engine = UpdateEngine(apiClient: mock)

        let operations = [
            UpdateOperation(id: UUID(), identifier: "SERIAL1", fieldUpdates: [
                .init(field: .assetTag, value: "ASSET-001"),
                .init(field: .deviceName, value: "My iPad"),
            ]),
        ]

        let results = await engine.execute(
            operations: operations,
            deviceType: .iOS,
            onProgress: nil
        )

        #expect(results.count == 1)
        if case .success = results[0].status {
            // Expected
        } else {
            Issue.record("Expected success status")
        }

        // Verify the device name MDM command was called separately
        #expect(mock.setMobileDeviceNameCalls.count == 1)
        #expect(mock.setMobileDeviceNameCalls[0].name == "My iPad")

        // Verify inventory update excluded deviceName
        #expect(mock.updateMobileDeviceCalls.count == 1)
        let updatedFields = mock.updateMobileDeviceCalls[0].fields
        #expect(updatedFields.count == 1)
        #expect(updatedFields[0].field == .assetTag)
    }

    @Test func reportsProgress() async {
        let mock = MockJamfProAPIClient()
        mock.lookupComputerResults = ["S1": "1", "S2": "2", "S3": "3"]
        let engine = UpdateEngine(apiClient: mock)

        let operations = (1...3).map { i in
            UpdateOperation(id: UUID(), identifier: "S\(i)", fieldUpdates: [
                .init(field: .assetTag, value: "A\(i)"),
            ])
        }

        var progressUpdates: [(Int, Int)] = []
        let results = await engine.execute(
            operations: operations,
            deviceType: .macOS,
            onProgress: { completed, total, _ in
                progressUpdates.append((completed, total))
            }
        )

        #expect(results.count == 3)
        #expect(progressUpdates.count == 3)
        #expect(progressUpdates.last?.0 == 3) // final completed count
        #expect(progressUpdates.last?.1 == 3) // total
    }
}
