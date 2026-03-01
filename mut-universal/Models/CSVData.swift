import Foundation

/// Parsed CSV data ready for processing.
struct CSVData: Sendable {
    let headers: [String]
    let rows: [[String]]

    var rowCount: Int { rows.count }
    var columnCount: Int { headers.count }

    /// The identifier column (always column 0).
    var identifierHeader: String { headers[0] }
}

/// A single update operation derived from a CSV row.
struct UpdateOperation: Identifiable, Sendable {
    let id: UUID
    let identifier: String
    let fieldUpdates: [FieldUpdate]

    struct FieldUpdate: Sendable {
        let field: UpdatableField
        let value: String
    }
}

/// Result of a single update operation.
struct UpdateResult: Identifiable, Sendable {
    let id: UUID
    let identifier: String
    let status: Status
    let timestamp: Date

    enum Status: Sendable {
        case success
        case failed(error: String)
        case skipped(reason: String)
    }
}
