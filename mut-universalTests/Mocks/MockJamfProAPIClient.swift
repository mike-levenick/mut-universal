import Foundation
@testable import mut_universal

final class MockJamfProAPIClient: JamfProAPIClientProtocol, @unchecked Sendable {
    // MARK: - Configurable Results

    var authenticateResult: Result<AuthToken, Error> = .success(
        AuthToken(accessToken: "mock-token", expiresAt: Date.now.addingTimeInterval(1800))
    )

    var lookupComputerResults: [String: String] = [:]
    var lookupMobileDeviceResults: [String: String] = [:]

    var updateComputerResult: Result<Void, Error> = .success(())
    var updateMobileDeviceResult: Result<Void, Error> = .success(())
    var invalidateTokenResult: Result<Void, Error> = .success(())

    // MARK: - Recorded Calls

    struct UpdateCall: Sendable {
        let id: String
        let fields: [UpdateOperation.FieldUpdate]
    }

    private(set) var authenticateCalls: [(serverURL: URL, clientID: String, clientSecret: String)] = []
    private(set) var lookupComputerCalls: [String] = []
    private(set) var lookupMobileDeviceCalls: [String] = []
    private(set) var updateComputerCalls: [UpdateCall] = []
    private(set) var updateMobileDeviceCalls: [UpdateCall] = []
    private(set) var invalidateTokenCallCount = 0

    // MARK: - JamfProAPIClientProtocol

    func authenticate(
        serverURL: URL,
        clientID: String,
        clientSecret: String
    ) async throws -> AuthToken {
        authenticateCalls.append((serverURL, clientID, clientSecret))
        return try authenticateResult.get()
    }

    func lookupComputer(bySerial serial: String) async throws -> String {
        lookupComputerCalls.append(serial)
        guard let id = lookupComputerResults[serial] else {
            throw MUTError.deviceNotFound(identifier: serial)
        }
        return id
    }

    func lookupMobileDevice(bySerial serial: String) async throws -> String {
        lookupMobileDeviceCalls.append(serial)
        guard let id = lookupMobileDeviceResults[serial] else {
            throw MUTError.deviceNotFound(identifier: serial)
        }
        return id
    }

    func updateComputerInventory(
        id: String,
        fields: [UpdateOperation.FieldUpdate]
    ) async throws {
        updateComputerCalls.append(UpdateCall(id: id, fields: fields))
        try updateComputerResult.get()
    }

    func updateMobileDeviceInventory(
        id: String,
        fields: [UpdateOperation.FieldUpdate]
    ) async throws {
        updateMobileDeviceCalls.append(UpdateCall(id: id, fields: fields))
        try updateMobileDeviceResult.get()
    }

    func invalidateToken() async throws {
        invalidateTokenCallCount += 1
        try invalidateTokenResult.get()
    }
}
