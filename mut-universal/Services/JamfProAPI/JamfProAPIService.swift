import Foundation
import OSLog

nonisolated final class JamfProAPIService: JamfProAPIClientProtocol, Sendable {
    private let tokenManager = TokenManager()
    private let session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - JamfProAPIClientProtocol

    func authenticate(
        serverURL: URL,
        clientID: String,
        clientSecret: String
    ) async throws -> AuthToken {
        await tokenManager.configure(serverURL: serverURL, clientID: clientID, clientSecret: clientSecret)
        return try await tokenManager.requestToken()
    }

    func lookupComputer(bySerial serial: String) async throws -> String {
        let filter = "hardware.serialNumber==\(serial)"
        let request = try await authenticatedRequest(
            for: "api/v1/computers-inventory",
            method: "GET",
            queryItems: [
                URLQueryItem(name: "section", value: "GENERAL"),
                URLQueryItem(name: "filter", value: filter)
            ]
        )

        Logger.api.info("Looking up computer by serial: \(serial)")
        let data = try await execute(request)

        let response: ComputerSearchResponse
        do {
            response = try JSONDecoder().decode(ComputerSearchResponse.self, from: data)
        } catch {
            throw MUTError.decodingError(underlying: error)
        }

        guard let result = response.results.first else {
            throw MUTError.deviceNotFound(identifier: serial)
        }

        Logger.api.info("Found computer ID \(result.id) for serial \(serial)")
        return result.id
    }

    func lookupMobileDevice(bySerial serial: String) async throws -> String {
        let filter = "serialNumber==\(serial)"
        let request = try await authenticatedRequest(
            for: "api/v2/mobile-devices",
            method: "GET",
            queryItems: [
                URLQueryItem(name: "section", value: "GENERAL"),
                URLQueryItem(name: "filter", value: filter)
            ]
        )

        Logger.api.info("Looking up mobile device by serial: \(serial)")
        let data = try await execute(request)

        let response: MobileDeviceSearchResponse
        do {
            response = try JSONDecoder().decode(MobileDeviceSearchResponse.self, from: data)
        } catch {
            throw MUTError.decodingError(underlying: error)
        }

        guard let result = response.results.first else {
            throw MUTError.deviceNotFound(identifier: serial)
        }

        Logger.api.info("Found mobile device ID \(result.id) for serial \(serial)")
        return result.id
    }

    func updateComputerInventory(
        id: String,
        fields: [UpdateOperation.FieldUpdate]
    ) async throws {
        let path = "api/v3/computers-inventory-detail/\(id)"
        var request = try await authenticatedRequest(for: path, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = buildComputerPatchBody(fields: fields)
        guard !body.isEmpty else {
            Logger.api.info("No updatable fields for computer \(id), skipping PATCH")
            return
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        Logger.api.info("Updating computer \(id) with \(fields.count) field(s)")
        _ = try await execute(request)
    }

    func updateMobileDeviceInventory(
        id: String,
        fields: [UpdateOperation.FieldUpdate]
    ) async throws {
        let path = "api/v2/mobile-devices/\(id)"
        var request = try await authenticatedRequest(for: path, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = buildMobileDevicePatchBody(fields: fields)
        guard !body.isEmpty else {
            Logger.api.info("No updatable fields for mobile device \(id), skipping PATCH")
            return
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        Logger.api.info("Updating mobile device \(id) with \(fields.count) field(s)")
        _ = try await execute(request)
    }

    func invalidateToken() async throws {
        try await tokenManager.invalidate()
    }

    // MARK: - Private Helpers

    private func authenticatedRequest(
        for path: String,
        method: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> URLRequest {
        let token = try await tokenManager.validToken()

        guard let serverURL = await tokenManager.configuredServerURL else {
            throw MUTError.missingCredentials
        }

        let baseURL = serverURL.appendingPathComponent(path)

        let url: URL
        if let queryItems, !queryItems.isEmpty {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            guard let built = components?.url else {
                throw MUTError.invalidURL(baseURL.absoluteString)
            }
            url = built
        } else {
            url = baseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    /// Build JSON body for PATCH /api/v3/computers-inventory-detail/{id}.
    /// Groups fields into sections using UpdatableField's apiSection/apiKey.
    func buildComputerPatchBody(fields: [UpdateOperation.FieldUpdate]) -> [String: Any] {
        var sections: [String: [String: Any]] = [:]

        for field in fields {
            let section = field.field.apiSection
            guard !section.isEmpty else { continue }

            if sections[section] == nil {
                sections[section] = [:]
            }
            sections[section]?[field.field.apiKey] = field.value
        }

        return sections
    }

    /// Build JSON body for PATCH /api/v2/mobile-devices/{id}.
    /// The mobile device endpoint has a different structure than computers:
    /// - "location" instead of "userAndLocation", with different key names
    /// - assetTag at top level instead of under "general" (barcodes not supported on mobile v2)
    /// - purchasing nested under "ios.purchasing"
    /// - device name as top-level "name" + "enforceName" (overrides computer's general.name)
    func buildMobileDevicePatchBody(fields: [UpdateOperation.FieldUpdate]) -> [String: Any] {
        var body: [String: Any] = [:]
        var location: [String: Any] = [:]
        var purchasing: [String: Any] = [:]

        // Mobile device key mappings differ from computer
        let mobileLocationKeys: [UpdatableField: String] = [
            .username: "username",
            .fullName: "realName",
            .emailAddress: "emailAddress",
            .position: "position",
            .phoneNumber: "phoneNumber",
            .building: "buildingId",
            .department: "departmentId",
        ]

        for field in fields {
            switch field.field {
            case .deviceName:
                body["name"] = field.value
                body["enforceName"] = true

            case .assetTag:
                body["assetTag"] = field.value

            case .barcode1, .barcode2:
                // Mobile device v2 endpoint does not support barcodes
                // Skip silently — these are computer-only fields
                continue

            case .poNumber:
                purchasing["poNumber"] = field.value
            case .vendor:
                purchasing["vendor"] = field.value
            case .purchasePrice:
                purchasing["purchasePrice"] = field.value

            default:
                if let key = mobileLocationKeys[field.field] {
                    location[key] = field.value
                }
            }
        }

        if !location.isEmpty {
            body["location"] = location
        }
        if !purchasing.isEmpty {
            body["ios"] = ["purchasing": purchasing]
        }

        return body
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw MUTError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MUTError.networkError(underlying: URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw MUTError.tokenExpired
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(TimeInterval.init)
            throw MUTError.rateLimited(retryAfter: retryAfter)
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.api.error("API error \(httpResponse.statusCode): \(message)")
            throw MUTError.apiError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}
