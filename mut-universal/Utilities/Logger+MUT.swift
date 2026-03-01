import OSLog

extension Logger {
    private static let subsystem = "com.mlev.mut-universal"

    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let api = Logger(subsystem: subsystem, category: "api")
    static let csv = Logger(subsystem: subsystem, category: "csv")
    static let updates = Logger(subsystem: subsystem, category: "updates")
    static let keychain = Logger(subsystem: subsystem, category: "keychain")
}
