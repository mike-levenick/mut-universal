import Testing
import Foundation
@testable import mut_universal

@Suite("LogRingBuffer Tests")
struct LogRingBufferTests {
    @Test("Appends entries and retrieves snapshot")
    func appendAndSnapshot() {
        let buffer = LogRingBuffer(capacity: 100)
        let entry = LogEntry(id: UUID(), timestamp: .now, category: .auth, level: .info, message: "test")

        buffer.append(entry)
        let snapshot = buffer.snapshot()

        #expect(snapshot.count == 1)
        #expect(snapshot[0].message == "test")
    }

    @Test("Enforces capacity limit")
    func capacityLimit() {
        let buffer = LogRingBuffer(capacity: 5)

        for i in 0..<10 {
            let entry = LogEntry(id: UUID(), timestamp: .now, category: .api, level: .info, message: "msg-\(i)")
            buffer.append(entry)
        }

        let snapshot = buffer.snapshot()
        #expect(snapshot.count == 5)
        #expect(snapshot[0].message == "msg-5")
        #expect(snapshot[4].message == "msg-9")
    }

    @Test("Clear empties the buffer")
    func clear() {
        let buffer = LogRingBuffer(capacity: 100)
        buffer.append(LogEntry(id: UUID(), timestamp: .now, category: .csv, level: .error, message: "err"))

        buffer.clear()
        #expect(buffer.snapshot().isEmpty)
    }

    @Test("Thread-safe concurrent writes")
    func concurrentWrites() async {
        let buffer = LogRingBuffer(capacity: 1000)

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let entry = LogEntry(id: UUID(), timestamp: .now, category: .updates, level: .info, message: "concurrent-\(i)")
                    buffer.append(entry)
                }
            }
        }

        #expect(buffer.snapshot().count == 100)
    }
}

@Suite("LogStore Tests")
struct LogStoreTests {
    @Test("Export text format includes header and entries")
    @MainActor
    func exportText() {
        let store = LogStore()
        let entry = LogEntry(
            id: UUID(),
            timestamp: Date(timeIntervalSince1970: 1709136000),
            category: .auth,
            level: .info,
            message: "Token obtained"
        )
        store.buffer.append(entry)
        store.sync()

        let exported = store.exportText()
        #expect(exported.contains("[INFO]"))
        #expect(exported.contains("[auth]"))
        #expect(exported.contains("Token obtained"))
        #expect(exported.contains("MUT Log Export"))
    }

    @Test("Sync copies buffer to entries")
    @MainActor
    func sync() {
        let store = LogStore()
        store.buffer.append(LogEntry(id: UUID(), timestamp: .now, category: .api, level: .warning, message: "warn"))

        #expect(store.entries.isEmpty)
        store.sync()
        #expect(store.entries.count == 1)
        #expect(store.entries[0].level == .warning)
    }

    @Test("Clear resets both buffer and entries")
    @MainActor
    func clear() {
        let store = LogStore()
        store.buffer.append(LogEntry(id: UUID(), timestamp: .now, category: .csv, level: .error, message: "err"))
        store.sync()

        store.clear()
        #expect(store.entries.isEmpty)
        #expect(store.buffer.snapshot().isEmpty)
    }
}

@Suite("LogLevel Tests")
struct LogLevelTests {
    @Test("Levels are comparable")
    func comparable() {
        #expect(LogLevel.info < LogLevel.warning)
        #expect(LogLevel.warning < LogLevel.error)
        #expect(!(LogLevel.error < LogLevel.info))
    }
}
