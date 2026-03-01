import Foundation

enum DeviceType: String, CaseIterable, Identifiable, Sendable {
    case macOS = "macOS Computers"
    case iOS = "iOS Devices"

    var id: String { rawValue }
}
