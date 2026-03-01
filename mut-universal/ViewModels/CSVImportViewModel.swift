import Observation
import Foundation
import OSLog

@Observable
final class CSVImportViewModel {
    var selectedDeviceType: DeviceType = .macOS
    var csvData: CSVData?
    var columnMapping: [Int: UpdatableField] = [:]
    var errorMessage: String?
    var fileName: String?

    private let parser = CSVParser()
    private let validator = CSVValidator()

    var isReadyToPreview: Bool {
        csvData != nil && !columnMapping.isEmpty
    }

    var availableFields: [UpdatableField] {
        UpdatableField.fields(for: selectedDeviceType)
    }

    func loadCSV(from url: URL) {
        errorMessage = nil

        do {
            let data = try parser.parse(fileURL: url)
            csvData = data
            fileName = url.lastPathComponent
            autoMapColumns()
            Logger.csv.info("Loaded CSV: \(data.rowCount) rows, \(data.columnCount) columns")
        } catch let error as MUTError {
            errorMessage = error.errorDescription
            csvData = nil
            fileName = nil
            Logger.csv.error("CSV load failed: \(error.errorDescription ?? "Unknown")")
        } catch {
            errorMessage = "Failed to load CSV: \(error.localizedDescription)"
            csvData = nil
            fileName = nil
            Logger.csv.error("CSV load failed: \(error.localizedDescription)")
        }
    }

    func autoMapColumns() {
        guard let csvData else { return }

        columnMapping = [:]

        let fields = availableFields
        for (index, header) in csvData.headers.enumerated() {
            if index == 0 { continue }

            let normalizedHeader = header.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            for field in fields {
                let normalizedFieldName = field.displayName.lowercased()
                if normalizedHeader == normalizedFieldName
                    || normalizedHeader == field.rawValue.lowercased()
                {
                    columnMapping[index] = field
                    break
                }
            }
        }

        Logger.csv.info("Auto-mapped \(self.columnMapping.count) of \(csvData.headers.count - 1) columns")
    }

    func validateAndPreview() -> [UpdateOperation]? {
        guard let csvData else { return nil }

        let result = validator.validate(
            csv: csvData,
            deviceType: selectedDeviceType,
            columnMapping: columnMapping
        )

        if !result.isValid {
            let errorMessages = result.errors.map(\.message).joined(separator: "\n")
            errorMessage = errorMessages
            return nil
        }

        return result.operations
    }

    func clearCSV() {
        csvData = nil
        fileName = nil
        columnMapping = [:]
        errorMessage = nil
    }

    func onDeviceTypeChanged() {
        columnMapping = [:]
        if csvData != nil {
            autoMapColumns()
        }
    }
}
