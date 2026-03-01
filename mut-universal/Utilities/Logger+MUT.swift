import OSLog

extension Logger {
    static let auth = MUTLogger(category: .auth)
    static let api = MUTLogger(category: .api)
    static let csv = MUTLogger(category: .csv)
    static let updates = MUTLogger(category: .updates)
    static let keychain = MUTLogger(category: .keychain)
}
