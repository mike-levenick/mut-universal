import Foundation
import Observation

@Observable
@MainActor
final class LogStore {
    private(set) var entries: [LogEntry] = []

    nonisolated let buffer: LogRingBuffer

    nonisolated init() {
        self.buffer = LogRingBuffer(capacity: 2000)
    }

    func sync() {
        entries = buffer.snapshot()
    }

    func exportText() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var lines: [String] = []
        lines.append("MUT Log Export — \(formatter.string(from: Date.now))")
        lines.append("===")
        lines.append("")

        for entry in entries {
            let ts = formatter.string(from: entry.timestamp)
            let level = entry.level.displayName.uppercased()
            lines.append("[\(ts)] [\(level)] [\(entry.category.rawValue)] \(entry.message)")
        }

        return lines.joined(separator: "\n")
    }

    func clear() {
        buffer.clear()
        entries = []
    }
}

final class LogRingBuffer: Sendable {
    private let lock = NSLock()
    private let capacity: Int
    nonisolated(unsafe) private var storage: [LogEntry] = []

    init(capacity: Int) {
        self.capacity = capacity
    }

    func append(_ entry: LogEntry) {
        lock.withLock {
            storage.append(entry)
            if storage.count > capacity {
                storage.removeFirst(storage.count - capacity)
            }
        }
    }

    func snapshot() -> [LogEntry] {
        lock.withLock { storage }
    }

    func clear() {
        lock.withLock { storage.removeAll() }
    }
}
