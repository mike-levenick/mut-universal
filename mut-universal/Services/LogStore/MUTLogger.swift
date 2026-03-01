import OSLog
import Foundation

/// A logging facade that writes to both Apple's unified log (OSLog)
/// and the in-app LogStore ring buffer.
///
/// Designed as a drop-in replacement for `Logger` in the static
/// extension properties. Call sites like `Logger.auth.info("...")`
/// continue to work unchanged.
struct MUTLogger: Sendable {
    private let osLogger: Logger
    let category: LogCategory

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _buffer: LogRingBuffer?
    nonisolated(unsafe) private static var _syncHandler: (@Sendable () -> Void)?

    static func configure(buffer: LogRingBuffer, syncHandler: @escaping @Sendable () -> Void) {
        lock.withLock {
            _buffer = buffer
            _syncHandler = syncHandler
        }
    }

    private static var buffer: LogRingBuffer? {
        lock.withLock { _buffer }
    }

    private static var syncHandler: (@Sendable () -> Void)? {
        lock.withLock { _syncHandler }
    }

    init(category: LogCategory) {
        self.category = category
        self.osLogger = Logger(
            subsystem: "com.mlev.mut-universal",
            category: category.rawValue
        )
    }

    func info(_ message: String) {
        osLogger.info("\(message, privacy: .public)")
        record(message, level: .info)
    }

    func error(_ message: String) {
        osLogger.error("\(message, privacy: .public)")
        record(message, level: .error)
    }

    func warning(_ message: String) {
        osLogger.warning("\(message, privacy: .public)")
        record(message, level: .warning)
    }

    private func record(_ message: String, level: LogLevel) {
        let entry = LogEntry(
            id: UUID(),
            timestamp: Date.now,
            category: category,
            level: level,
            message: message
        )
        Self.buffer?.append(entry)
        if let handler = Self.syncHandler {
            Task { @MainActor in handler() }
        }
    }
}
