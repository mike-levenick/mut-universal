import Testing
@testable import mut_universal

struct CSVValidatorTests {
    let validator = CSVValidator()

    @Test func validCSVProducesOperations() {
        let csv = CSVData(
            headers: ["Serial", "Asset Tag", "Username"],
            rows: [
                ["ABC123", "1001", "jsmith"],
                ["DEF456", "1002", "jdoe"],
            ]
        )
        let mapping: [Int: UpdatableField] = [1: .assetTag, 2: .username]

        let result = validator.validate(csv: csv, deviceType: .macOS, columnMapping: mapping)

        #expect(result.isValid)
        #expect(result.operations.count == 2)
        #expect(result.operations[0].identifier == "ABC123")
        #expect(result.operations[0].fieldUpdates.count == 2)
        #expect(result.operations[1].identifier == "DEF456")
    }

    @Test func emptyIdentifierGeneratesError() {
        let csv = CSVData(
            headers: ["Serial", "Asset Tag"],
            rows: [
                ["", "1001"],
                ["DEF456", "1002"],
            ]
        )
        let mapping: [Int: UpdatableField] = [1: .assetTag]

        let result = validator.validate(csv: csv, deviceType: .macOS, columnMapping: mapping)

        #expect(!result.isValid)
        #expect(result.errors.count == 1)
        #expect(result.errors[0].row == 2)
        #expect(result.operations.count == 1)
        #expect(result.operations[0].identifier == "DEF456")
    }

    @Test func emptyValuesGenerateWarnings() {
        let csv = CSVData(
            headers: ["Serial", "Asset Tag", "Username"],
            rows: [
                ["ABC123", "", "jsmith"],
            ]
        )
        let mapping: [Int: UpdatableField] = [1: .assetTag, 2: .username]

        let result = validator.validate(csv: csv, deviceType: .macOS, columnMapping: mapping)

        #expect(result.isValid)
        let emptyWarnings = result.warnings.filter { $0.message.contains("empty") }
        #expect(emptyWarnings.count == 1)
    }

    @Test func unmappedColumnsAreSkipped() {
        let csv = CSVData(
            headers: ["Serial", "Asset Tag", "Notes", "Username"],
            rows: [
                ["ABC123", "1001", "Some note", "jsmith"],
            ]
        )
        // Only map columns 1 and 3; column 2 ("Notes") is unmapped
        let mapping: [Int: UpdatableField] = [1: .assetTag, 3: .username]

        let result = validator.validate(csv: csv, deviceType: .macOS, columnMapping: mapping)

        #expect(result.isValid)
        #expect(result.operations[0].fieldUpdates.count == 2)

        let fields = result.operations[0].fieldUpdates.map(\.field)
        #expect(fields.contains(.assetTag))
        #expect(fields.contains(.username))
    }

    @Test func deviceNameAcceptedForMacOS() {
        let csv = CSVData(
            headers: ["Serial", "Device Name"],
            rows: [
                ["ABC123", "MyMac"],
            ]
        )
        let mapping: [Int: UpdatableField] = [1: .deviceName]

        let result = validator.validate(csv: csv, deviceType: .macOS, columnMapping: mapping)

        #expect(result.isValid)
        let deviceNameWarnings = result.warnings.filter { $0.message.contains("Device Name") }
        #expect(deviceNameWarnings.isEmpty)
    }
}
