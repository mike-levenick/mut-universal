import Foundation
import Security
import OSLog

nonisolated struct KeychainService: Sendable {
    private static let service = "com.mlev.mut-universal"
    private static let account = "api-credentials"

    struct Credentials: Codable, Sendable {
        let serverURL: String
        let clientID: String
        let clientSecret: String
    }

    func save(_ credentials: Credentials) throws {
        let data = try JSONEncoder().encode(credentials)

        // Delete any existing item first to avoid errSecDuplicateItem
        delete()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            Logger.keychain.error("Failed to save credentials: \(status)")
            throw MUTError.apiError(statusCode: Int(status), message: "Keychain save failed")
        }

        Logger.keychain.info("Credentials saved to keychain")
    }

    func load() -> Credentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                Logger.keychain.warning("Keychain load returned status: \(status)")
            }
            return nil
        }

        do {
            let credentials = try JSONDecoder().decode(Credentials.self, from: data)
            Logger.keychain.info("Credentials loaded from keychain")
            return credentials
        } catch {
            Logger.keychain.error("Failed to decode keychain data: \(error)")
            return nil
        }
    }

    @discardableResult
    func delete() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            Logger.keychain.info("Credentials deleted from keychain")
            return true
        } else if status == errSecItemNotFound {
            return false
        } else {
            Logger.keychain.warning("Keychain delete returned status: \(status)")
            return false
        }
    }
}
