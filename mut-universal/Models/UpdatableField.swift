import Foundation

/// A field that can be mass-updated via the Jamf Pro API.
/// Each case maps to a specific section and key in the API's JSON body.
enum UpdatableField: String, CaseIterable, Identifiable, Sendable {
    case assetTag
    case barcode1
    case barcode2
    case username
    case fullName
    case emailAddress
    case building
    case department
    case position
    case phoneNumber
    case poNumber
    case vendor
    case purchasePrice
    case deviceName // iOS only — triggers MDM command via Classic API

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .assetTag: "Asset Tag"
        case .barcode1: "Barcode 1"
        case .barcode2: "Barcode 2"
        case .username: "Username"
        case .fullName: "Full Name"
        case .emailAddress: "Email Address"
        case .building: "Building (ID)"
        case .department: "Department (ID)"
        case .position: "Position"
        case .phoneNumber: "Phone Number"
        case .poNumber: "PO Number"
        case .vendor: "Vendor"
        case .purchasePrice: "Purchase Price"
        case .deviceName: "Device Name"
        }
    }

    /// The section in the PATCH JSON body (e.g., "general", "userAndLocation", "purchasing").
    var apiSection: String {
        switch self {
        case .assetTag, .barcode1, .barcode2:
            "general"
        case .username, .fullName, .emailAddress, .building, .department, .position, .phoneNumber:
            "userAndLocation"
        case .poNumber, .vendor, .purchasePrice:
            "purchasing"
        case .deviceName:
            "" // Handled via Classic API MDM command
        }
    }

    /// The JSON key within the section.
    var apiKey: String {
        switch self {
        case .assetTag: "assetTag"
        case .barcode1: "barcode1"
        case .barcode2: "barcode2"
        case .username: "username"
        case .fullName: "realname"
        case .emailAddress: "email"
        case .building: "buildingId"
        case .department: "departmentId"
        case .position: "position"
        case .phoneNumber: "phone"
        case .poNumber: "poNumber"
        case .vendor: "vendor"
        case .purchasePrice: "purchasePrice"
        case .deviceName: "" // Not used — Classic API
        }
    }

    /// Whether this field requires the Classic API instead of the Jamf Pro API.
    var requiresClassicAPI: Bool {
        self == .deviceName
    }

    /// Fields available for a given device type.
    static func fields(for deviceType: DeviceType) -> [UpdatableField] {
        switch deviceType {
        case .macOS:
            allCases.filter { $0 != .deviceName }
        case .iOS:
            allCases
        }
    }
}
