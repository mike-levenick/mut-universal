import Foundation

// MARK: - OAuth Token Response

nonisolated struct OAuthTokenResponse: Decodable, Sendable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
    }
}

// MARK: - Computer Search

nonisolated struct ComputerSearchResponse: Decodable, Sendable {
    let totalCount: Int
    let results: [ComputerSearchResult]
}

nonisolated struct ComputerSearchResult: Decodable, Sendable {
    let id: String
    let general: General?

    struct General: Decodable, Sendable {
        let name: String?
    }
}

// MARK: - Mobile Device Search

nonisolated struct MobileDeviceSearchResponse: Decodable, Sendable {
    let totalCount: Int
    let results: [MobileDeviceSearchResult]
}

nonisolated struct MobileDeviceSearchResult: Decodable, Sendable {
    let id: String
    let name: String?
}
