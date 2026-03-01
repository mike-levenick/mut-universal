import Foundation
import OSLog

actor TokenManager {
    private var serverURL: URL?
    private var clientID: String?
    private var clientSecret: String?
    private var currentToken: AuthToken?

    func configure(serverURL: URL, clientID: String, clientSecret: String) {
        self.serverURL = serverURL
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.currentToken = nil
    }

    @discardableResult
    func requestToken() async throws -> AuthToken {
        guard let serverURL, let clientID, let clientSecret else {
            throw MUTError.missingCredentials
        }

        let tokenURL = serverURL.appendingPathComponent("api/oauth/token")
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=client_credentials&client_id=\(urlEncode(clientID))&client_secret=\(urlEncode(clientSecret))"
        request.httpBody = body.data(using: .utf8)

        Logger.auth.info("Requesting OAuth token from \(tokenURL.absoluteString)")

        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MUTError.networkError(underlying: URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.auth.error("Token request failed with status \(httpResponse.statusCode): \(message)")
            throw MUTError.authenticationFailed(statusCode: httpResponse.statusCode, message: message)
        }

        let tokenResponse: OAuthTokenResponse
        do {
            tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        } catch {
            throw MUTError.decodingError(underlying: error)
        }

        let token = AuthToken(
            accessToken: tokenResponse.accessToken,
            expiresAt: Date.now.addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        )

        currentToken = token
        Logger.auth.info("Token obtained, expires in \(tokenResponse.expiresIn)s")
        return token
    }

    func validToken() async throws -> AuthToken {
        if let token = currentToken, !token.expiresWithin(60) {
            return token
        }
        Logger.auth.info("Token missing or near expiry, renewing")
        return try await requestToken()
    }

    func invalidate() async throws {
        guard let serverURL, let token = currentToken else { return }

        let url = serverURL.appendingPathComponent("api/v1/auth/invalidate-token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")

        Logger.auth.info("Invalidating token")

        let (_, response) = try await performRequest(request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 204 {
            Logger.auth.warning("Token invalidation returned status \(httpResponse.statusCode)")
        }

        currentToken = nil
    }

    var configuredServerURL: URL? {
        serverURL
    }

    func reset() {
        serverURL = nil
        clientID = nil
        clientSecret = nil
        currentToken = nil
        Logger.auth.info("Token manager reset")
    }

    // MARK: - Private

    private func urlEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw MUTError.networkError(underlying: error)
        }
    }
}
