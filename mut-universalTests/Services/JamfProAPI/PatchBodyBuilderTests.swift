import Testing
import Foundation
@testable import mut_universal

@Suite("PATCH body builders")
struct PatchBodyBuilderTests {
    private let service = JamfProAPIService()

    // MARK: - Computer body (v3)

    @Test("Computer body groups fields into correct sections")
    func computerBodySections() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .assetTag, value: "ASSET-001"),
            .init(field: .username, value: "jsmith"),
            .init(field: .poNumber, value: "PO-123"),
        ]

        let body = service.buildComputerPatchBody(fields: fields)

        let general = body["general"] as? [String: Any]
        #expect(general?["assetTag"] as? String == "ASSET-001")

        let userAndLocation = body["userAndLocation"] as? [String: Any]
        #expect(userAndLocation?["username"] as? String == "jsmith")

        let purchasing = body["purchasing"] as? [String: Any]
        #expect(purchasing?["poNumber"] as? String == "PO-123")
    }

    @Test("Computer body uses correct keys for user/location fields")
    func computerBodyUserLocationKeys() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .fullName, value: "John Smith"),
            .init(field: .emailAddress, value: "j@example.com"),
            .init(field: .phoneNumber, value: "555-1234"),
            .init(field: .building, value: "5"),
            .init(field: .department, value: "12"),
            .init(field: .position, value: "Manager"),
        ]

        let body = service.buildComputerPatchBody(fields: fields)
        let section = body["userAndLocation"] as? [String: Any]

        #expect(section?["realname"] as? String == "John Smith")
        #expect(section?["email"] as? String == "j@example.com")
        #expect(section?["phone"] as? String == "555-1234")
        #expect(section?["buildingId"] as? String == "5")
        #expect(section?["departmentId"] as? String == "12")
        #expect(section?["position"] as? String == "Manager")
    }

    @Test("Computer body puts barcodes under general")
    func computerBodyBarcodes() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .barcode1, value: "BC1"),
            .init(field: .barcode2, value: "BC2"),
        ]

        let body = service.buildComputerPatchBody(fields: fields)
        let general = body["general"] as? [String: Any]

        #expect(general?["barcode1"] as? String == "BC1")
        #expect(general?["barcode2"] as? String == "BC2")
    }

    @Test("Computer body skips device name field")
    func computerBodySkipsDeviceName() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .deviceName, value: "My Mac"),
            .init(field: .assetTag, value: "ASSET-001"),
        ]

        let body = service.buildComputerPatchBody(fields: fields)

        // deviceName has empty apiSection, should be skipped
        #expect(body["name"] == nil)
        #expect(body["deviceName"] == nil)

        let general = body["general"] as? [String: Any]
        #expect(general?["assetTag"] as? String == "ASSET-001")
    }

    // MARK: - Mobile device body (v2)

    @Test("Mobile body puts asset tag at top level")
    func mobileBodyTopLevelAssetTag() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .assetTag, value: "iPad-001"),
        ]

        let body = service.buildMobileDevicePatchBody(fields: fields)

        #expect(body["assetTag"] as? String == "iPad-001")
        #expect(body["general"] == nil) // NOT nested under general
    }

    @Test("Mobile body uses location section with correct keys")
    func mobileBodyLocationKeys() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .fullName, value: "Jane Doe"),
            .init(field: .emailAddress, value: "j@example.com"),
            .init(field: .phoneNumber, value: "555-9876"),
            .init(field: .building, value: "3"),
            .init(field: .department, value: "7"),
            .init(field: .position, value: "Engineer"),
            .init(field: .username, value: "jdoe"),
        ]

        let body = service.buildMobileDevicePatchBody(fields: fields)
        let location = body["location"] as? [String: Any]

        // Mobile v2 uses different keys than computer v3
        #expect(location?["realName"] as? String == "Jane Doe") // NOT "realname"
        #expect(location?["emailAddress"] as? String == "j@example.com") // NOT "email"
        #expect(location?["phoneNumber"] as? String == "555-9876") // NOT "phone"
        #expect(location?["buildingId"] as? String == "3")
        #expect(location?["departmentId"] as? String == "7")
        #expect(location?["position"] as? String == "Engineer")
        #expect(location?["username"] as? String == "jdoe")

        // Should NOT have computer-style section
        #expect(body["userAndLocation"] == nil)
    }

    @Test("Mobile body nests purchasing under ios")
    func mobileBodyPurchasingNesting() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .poNumber, value: "PO-456"),
            .init(field: .vendor, value: "Apple"),
            .init(field: .purchasePrice, value: "$999"),
        ]

        let body = service.buildMobileDevicePatchBody(fields: fields)

        // Purchasing is nested under ios.purchasing, not top-level
        #expect(body["purchasing"] == nil)

        let ios = body["ios"] as? [String: Any]
        let purchasing = ios?["purchasing"] as? [String: Any]
        #expect(purchasing?["poNumber"] as? String == "PO-456")
        #expect(purchasing?["vendor"] as? String == "Apple")
        #expect(purchasing?["purchasePrice"] as? String == "$999")
    }

    @Test("Mobile body sets device name with enforceName")
    func mobileBodyDeviceName() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .deviceName, value: "iPad-Reception"),
        ]

        let body = service.buildMobileDevicePatchBody(fields: fields)

        #expect(body["name"] as? String == "iPad-Reception")
        #expect(body["enforceName"] as? Bool == true)
    }

    @Test("Mobile body skips barcodes")
    func mobileBodySkipsBarcodes() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .barcode1, value: "BC1"),
            .init(field: .barcode2, value: "BC2"),
            .init(field: .assetTag, value: "iPad-001"),
        ]

        let body = service.buildMobileDevicePatchBody(fields: fields)

        #expect(body["assetTag"] as? String == "iPad-001")
        // Barcodes not supported on mobile v2 — should not appear
        #expect(body["barcode1"] == nil)
        #expect(body["barcode2"] == nil)
        #expect(body["general"] == nil)
    }

    @Test("Mobile body with all field types at once")
    func mobileBodyAllFieldTypes() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .assetTag, value: "iPad-001"),
            .init(field: .username, value: "jsmith"),
            .init(field: .fullName, value: "John Smith"),
            .init(field: .poNumber, value: "PO-789"),
            .init(field: .deviceName, value: "iPad-JSmith"),
        ]

        let body = service.buildMobileDevicePatchBody(fields: fields)

        // Top-level fields
        #expect(body["assetTag"] as? String == "iPad-001")
        #expect(body["name"] as? String == "iPad-JSmith")
        #expect(body["enforceName"] as? Bool == true)

        // Location
        let location = body["location"] as? [String: Any]
        #expect(location?["username"] as? String == "jsmith")
        #expect(location?["realName"] as? String == "John Smith")

        // Purchasing
        let ios = body["ios"] as? [String: Any]
        let purchasing = ios?["purchasing"] as? [String: Any]
        #expect(purchasing?["poNumber"] as? String == "PO-789")
    }

    // MARK: - Edge cases

    @Test("Empty fields produces empty body")
    func emptyFields() {
        let computerBody = service.buildComputerPatchBody(fields: [])
        #expect(computerBody.isEmpty)

        let mobileBody = service.buildMobileDevicePatchBody(fields: [])
        #expect(mobileBody.isEmpty)
    }

    @Test("Single field produces minimal body")
    func singleField() {
        let fields: [UpdateOperation.FieldUpdate] = [
            .init(field: .username, value: "jsmith"),
        ]

        let computerBody = service.buildComputerPatchBody(fields: fields)
        #expect(computerBody.count == 1)
        #expect((computerBody["userAndLocation"] as? [String: Any])?["username"] as? String == "jsmith")

        let mobileBody = service.buildMobileDevicePatchBody(fields: fields)
        #expect(mobileBody.count == 1)
        #expect((mobileBody["location"] as? [String: Any])?["username"] as? String == "jsmith")
    }
}
