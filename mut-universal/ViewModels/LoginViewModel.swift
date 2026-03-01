import Observation
import Foundation
import OSLog

@Observable
final class LoginViewModel {
    var serverURL: String = ""
    var clientID: String = ""
    var clientSecret: String = ""
    var rememberMe: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    var isFormValid: Bool {
        !serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !clientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func authenticate(using apiClient: any JamfProAPIClientProtocol) async -> Bool {
        guard let url = normalizedServerURL() else {
            errorMessage = "Please enter a valid Jamf Pro URL."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let trimmedClientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedClientSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)

            _ = try await apiClient.authenticate(
                serverURL: url,
                clientID: trimmedClientID,
                clientSecret: trimmedClientSecret
            )

            Logger.auth.info("Authentication successful for \(url.absoluteString)")

            if rememberMe {
                let credentials = KeychainService.Credentials(
                    serverURL: url.absoluteString,
                    clientID: trimmedClientID,
                    clientSecret: trimmedClientSecret
                )
                try? KeychainService().save(credentials)
            } else {
                KeychainService().delete()
            }

            isLoading = false
            return true
        } catch let error as MUTError {
            errorMessage = error.errorDescription
            Logger.auth.error("Authentication failed: \(error.errorDescription ?? "Unknown error")")
            isLoading = false
            return false
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            Logger.auth.error("Authentication failed with unexpected error: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }

    func loadSavedCredentials() {
        guard let credentials = KeychainService().load() else { return }
        serverURL = credentials.serverURL
        clientID = credentials.clientID
        clientSecret = credentials.clientSecret
        rememberMe = true
        Logger.auth.info("Credentials loaded from Keychain")
    }

    func normalizedServerURL() -> URL? {
        var urlString = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)

        if urlString.isEmpty { return nil }

        if !urlString.hasPrefix("https://") && !urlString.hasPrefix("http://") {
            urlString = "https://\(urlString)"
        }

        while urlString.hasSuffix("/") {
            urlString.removeLast()
        }

        return URL(string: urlString)
    }
}
