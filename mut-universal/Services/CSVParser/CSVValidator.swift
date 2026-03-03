import Foundation
import OSLog

nonisolated struct CSVValidator: Sendable {

    struct ValidationResult: Sendable {
        let operations: [UpdateOperation]
        let warnings: [Warning]
        let errors: [ValidationError]

        var isValid: Bool { errors.isEmpty }
    }

    struct Warning: Sendable, Identifiable {
        let id: UUID
        let row: Int
        let message: String
    }

    struct ValidationError: Sendable, Identifiable {
        let id: UUID
        let row: Int?
        let message: String
    }

    func validate(
        csv: CSVData,
        deviceType: DeviceType,
        columnMapping: [Int: UpdatableField]
    ) -> ValidationResult {
        var operations: [UpdateOperation] = []
        var warnings: [Warning] = []
        var errors: [ValidationError] = []

        for (rowIndex, row) in csv.rows.enumerated() {
            let rowNumber = rowIndex + 2 // 1-indexed, header is row 1

            let identifier = row[0]
            guard !identifier.isEmpty else {
                errors.append(ValidationError(
                    id: UUID(),
                    row: rowNumber,
                    message: "Row \(rowNumber) is missing an identifier in column 1."
                ))
                continue
            }

            var fieldUpdates: [UpdateOperation.FieldUpdate] = []

            for (columnIndex, field) in columnMapping {
                guard columnIndex < row.count else { continue }

                let value = row[columnIndex]
                if value.isEmpty {
                    warnings.append(Warning(
                        id: UUID(),
                        row: rowNumber,
                        message: "Row \(rowNumber), column \(columnIndex + 1) (\(field.displayName)) is empty."
                    ))
                }

                fieldUpdates.append(UpdateOperation.FieldUpdate(field: field, value: value))
            }

            operations.append(UpdateOperation(
                id: UUID(),
                identifier: identifier,
                fieldUpdates: fieldUpdates
            ))
        }

        Logger.csv.info("Validation complete: \(operations.count) operations, \(warnings.count) warnings, \(errors.count) errors")
        return ValidationResult(operations: operations, warnings: warnings, errors: errors)
    }
}
