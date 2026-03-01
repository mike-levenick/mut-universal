import Foundation
import SwiftUI

struct LogEntry: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let category: LogCategory
    let level: LogLevel
    let message: String
}

enum LogCategory: String, CaseIterable, Identifiable, Sendable {
    case auth
    case api
    case csv
    case updates
    case keychain

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auth: "Auth"
        case .api: "API"
        case .csv: "CSV"
        case .updates: "Updates"
        case .keychain: "Keychain"
        }
    }
}

enum LogLevel: Int, CaseIterable, Comparable, Identifiable, Sendable {
    case info = 0
    case warning = 1
    case error = 2

    var id: String { displayName }

    var displayName: String {
        switch self {
        case .info: "Info"
        case .warning: "Warning"
        case .error: "Error"
        }
    }

    var systemImage: String {
        switch self {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: .blue
        case .warning: .orange
        case .error: .red
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
