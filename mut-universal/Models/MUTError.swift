import Foundation

enum MUTError: LocalizedError {
    // Auth errors
    case invalidURL(String)
    case authenticationFailed(statusCode: Int, message: String)
    case tokenExpired
    case missingCredentials

    // API errors
    case apiError(statusCode: Int, message: String)
    case networkError(underlying: Error)
    case decodingError(underlying: Error)
    case rateLimited(retryAfter: TimeInterval?)

    // CSV errors
    case csvEmpty
    case csvMissingHeader
    case csvInvalidRowCount(expected: Int, actual: Int, row: Int)
    case csvParsingFailed(row: Int, detail: String)

    // Update errors
    case deviceNotFound(identifier: String)
    case updateFailed(identifier: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            "Invalid Jamf Pro URL: \(url)"
        case .authenticationFailed(let code, let message):
            "Authentication failed (\(code)): \(message)"
        case .tokenExpired:
            "Session expired. Please sign in again."
        case .missingCredentials:
            "Missing client credentials. Please sign in."
        case .apiError(let code, let message):
            "API error (\(code)): \(message)"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        case .decodingError:
            "Failed to parse server response."
        case .rateLimited:
            "Rate limited by Jamf Pro. Please wait and try again."
        case .csvEmpty:
            "The CSV file is empty."
        case .csvMissingHeader:
            "The CSV file is missing a header row."
        case .csvInvalidRowCount(let expected, let actual, let row):
            "Row \(row) has \(actual) columns, expected \(expected)."
        case .csvParsingFailed(let row, let detail):
            "CSV parsing failed at row \(row): \(detail)"
        case .deviceNotFound(let identifier):
            "Device not found: \(identifier)"
        case .updateFailed(let identifier, let reason):
            "Update failed for \(identifier): \(reason)"
        }
    }
}
