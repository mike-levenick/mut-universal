import Foundation

/// Protocol defining all Jamf Pro API operations needed by MUT.
/// Implementations must be safe to call from any actor context.
protocol JamfProAPIClientProtocol: Sendable {
    /// Authenticate with client credentials and obtain a bearer token.
    func authenticate(
        serverURL: URL,
        clientID: String,
        clientSecret: String
    ) async throws -> AuthToken

    /// Look up a computer's Jamf Pro ID by serial number.
    func lookupComputer(bySerial serial: String) async throws -> String

    /// Look up a mobile device's Jamf Pro ID by serial number.
    func lookupMobileDevice(bySerial serial: String) async throws -> String

    /// Update inventory fields on a macOS computer.
    func updateComputerInventory(
        id: String,
        fields: [UpdateOperation.FieldUpdate]
    ) async throws

    /// Update inventory fields on an iOS device.
    func updateMobileDeviceInventory(
        id: String,
        fields: [UpdateOperation.FieldUpdate]
    ) async throws

    /// Send a DeviceName MDM command to an iOS device (Classic API).
    func setMobileDeviceName(
        id: String,
        name: String
    ) async throws

    /// Invalidate the current bearer token.
    func invalidateToken() async throws
}

/// Represents an OAuth bearer token with expiration.
struct AuthToken: Sendable {
    let accessToken: String
    let expiresAt: Date

    var isExpired: Bool {
        Date.now >= expiresAt
    }

    /// Returns true if the token will expire within the given interval.
    func expiresWithin(_ interval: TimeInterval) -> Bool {
        Date.now.addingTimeInterval(interval) >= expiresAt
    }
}
