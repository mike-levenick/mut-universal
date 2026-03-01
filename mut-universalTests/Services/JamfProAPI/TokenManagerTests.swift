import Testing
import Foundation
@testable import mut_universal

struct AuthTokenTests {
    @Test func tokenIsExpiredWhenDateIsPast() {
        let token = AuthToken(
            accessToken: "test",
            expiresAt: Date.now.addingTimeInterval(-60)
        )
        #expect(token.isExpired)
    }

    @Test func tokenIsNotExpiredWhenDateIsFuture() {
        let token = AuthToken(
            accessToken: "test",
            expiresAt: Date.now.addingTimeInterval(600)
        )
        #expect(!token.isExpired)
    }

    @Test func expiresWithinReturnsTrueWhenCloseToExpiry() {
        let token = AuthToken(
            accessToken: "test",
            expiresAt: Date.now.addingTimeInterval(30)
        )
        #expect(token.expiresWithin(60))
    }

    @Test func expiresWithinReturnsFalseWhenFarFromExpiry() {
        let token = AuthToken(
            accessToken: "test",
            expiresAt: Date.now.addingTimeInterval(3600)
        )
        #expect(!token.expiresWithin(60))
    }

    @Test func expiresWithinReturnsTrueForExpiredToken() {
        let token = AuthToken(
            accessToken: "test",
            expiresAt: Date.now.addingTimeInterval(-10)
        )
        #expect(token.expiresWithin(0))
    }

    @Test func tokenStoresAccessToken() {
        let token = AuthToken(
            accessToken: "my-bearer-token",
            expiresAt: Date.now.addingTimeInterval(1800)
        )
        #expect(token.accessToken == "my-bearer-token")
    }
}

struct OAuthTokenResponseTests {
    @Test func decodesFromJSON() throws {
        let json = """
        {
            "access_token": "eyJ0eXAi...",
            "token_type": "bearer",
            "expires_in": 1200,
            "scope": ""
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: json)
        #expect(response.accessToken == "eyJ0eXAi...")
        #expect(response.tokenType == "bearer")
        #expect(response.expiresIn == 1200)
        #expect(response.scope == "")
    }

    @Test func decodesWithNullScope() throws {
        let json = """
        {
            "access_token": "token",
            "token_type": "bearer",
            "expires_in": 600
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: json)
        #expect(response.accessToken == "token")
        #expect(response.scope == nil)
    }
}

struct MockJamfProAPIClientTests {
    @Test func mockRecordsAuthenticateCalls() async throws {
        let mock = MockJamfProAPIClient()
        let url = URL(string: "https://example.jamfcloud.com")!

        let token = try await mock.authenticate(serverURL: url, clientID: "id", clientSecret: "secret")
        #expect(token.accessToken == "mock-token")
        #expect(mock.authenticateCalls.count == 1)
        #expect(mock.authenticateCalls[0].clientID == "id")
    }

    @Test func mockLookupComputerReturnsConfiguredResult() async throws {
        let mock = MockJamfProAPIClient()
        mock.lookupComputerResults["ABC123"] = "42"

        let id = try await mock.lookupComputer(bySerial: "ABC123")
        #expect(id == "42")
    }

    @Test func mockLookupComputerThrowsWhenNotConfigured() async {
        let mock = MockJamfProAPIClient()

        await #expect(throws: MUTError.self) {
            _ = try await mock.lookupComputer(bySerial: "UNKNOWN")
        }
    }

    @Test func mockRecordsUpdateCalls() async throws {
        let mock = MockJamfProAPIClient()
        let fields = [
            UpdateOperation.FieldUpdate(field: .assetTag, value: "12345")
        ]

        try await mock.updateComputerInventory(id: "1", fields: fields)
        #expect(mock.updateComputerCalls.count == 1)
        #expect(mock.updateComputerCalls[0].id == "1")
        #expect(mock.updateComputerCalls[0].fields.count == 1)
    }
}
