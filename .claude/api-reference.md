# Jamf Pro API Reference — Endpoints Used by MUT

Quick reference for the API endpoints MUT uses. Sourced from the Jamf Pro API docs and OpenAPI schema at `https://<jamf-url>/api/schema`.

## Computer Inventory Update

**Endpoint:** `PATCH /api/v3/computers-inventory-detail/{id}`
**Purpose:** Update specific fields on a computer

### Request Body

```json
{
  "general": {
    "name": "string",
    "barcode1": "string",
    "barcode2": "string",
    "assetTag": "string",
    "siteId": "string",
    "extensionAttributes": [
      { "definitionId": "string", "values": ["string"] }
    ]
  },
  "purchasing": {
    "poNumber": "string",
    "vendor": "string",
    "purchasePrice": "string",
    "purchasingAccount": "string",
    "purchasingContact": "string",
    "leased": true,
    "purchased": true,
    "poDate": "2019-01-01",
    "warrantyDate": "2019-01-01",
    "leaseDate": "2019-01-01",
    "appleCareId": "string",
    "lifeExpectancy": 5,
    "extensionAttributes": [
      { "definitionId": "string", "values": ["string"] }
    ]
  },
  "userAndLocation": {
    "username": "string",
    "realname": "string",
    "email": "string",
    "position": "string",
    "phone": "string",
    "departmentId": "string",
    "buildingId": "string",
    "room": "string",
    "extensionAttributes": [
      { "definitionId": "string", "values": ["string"] }
    ]
  }
}
```

### Field Key Reference (computer)

| MUT Field | API Section | API Key |
|---|---|---|
| Asset Tag | `general` | `assetTag` |
| Barcode 1 | `general` | `barcode1` |
| Barcode 2 | `general` | `barcode2` |
| Username | `userAndLocation` | `username` |
| Full Name | `userAndLocation` | `realname` |
| Email Address | `userAndLocation` | `email` |
| Position | `userAndLocation` | `position` |
| Phone Number | `userAndLocation` | `phone` |
| Building (ID) | `userAndLocation` | `buildingId` |
| Department (ID) | `userAndLocation` | `departmentId` |
| PO Number | `purchasing` | `poNumber` |
| Vendor | `purchasing` | `vendor` |
| Purchase Price | `purchasing` | `purchasePrice` |

---

## Mobile Device Update

**Endpoint:** `PATCH /api/v2/mobile-devices/{id}`
**Purpose:** Update fields on a mobile device that are allowed to be modified by users

### Request Body

```json
{
  "name": "string",
  "enforceName": true,
  "assetTag": "string",
  "siteId": "string",
  "location": {
    "username": "string",
    "realName": "string",
    "emailAddress": "string",
    "position": "string",
    "phoneNumber": "string",
    "departmentId": "string",
    "buildingId": "string",
    "room": "string"
  },
  "updatedExtensionAttributes": [
    {
      "name": "string",
      "type": "STRING",
      "value": ["string"]
    }
  ],
  "ios": {
    "purchasing": {
      "poNumber": "string",
      "vendor": "string",
      "purchasePrice": "string",
      "purchasingAccount": "string",
      "purchasingContact": "string",
      "purchased": true,
      "leased": false,
      "poDate": "2019-01-01T00:00:00.000Z",
      "warrantyExpiresDate": "2019-01-01T00:00:00.000Z",
      "leaseExpiresDate": "2019-01-01T00:00:00.000Z",
      "appleCareId": "string",
      "lifeExpectancy": 7
    }
  }
}
```

### Field Key Reference (mobile device)

| MUT Field | API Section | API Key | Notes |
|---|---|---|---|
| Asset Tag | *(top-level)* | `assetTag` | NOT nested under a section |
| Username | `location` | `username` | |
| Full Name | `location` | `realName` | Capital N (differs from computer `realname`) |
| Email Address | `location` | `emailAddress` | Computer uses `email` |
| Position | `location` | `position` | |
| Phone Number | `location` | `phoneNumber` | Computer uses `phone` |
| Building (ID) | `location` | `buildingId` | |
| Department (ID) | `location` | `departmentId` | |
| PO Number | `ios.purchasing` | `poNumber` | Nested under `ios` |
| Vendor | `ios.purchasing` | `vendor` | Nested under `ios` |
| Purchase Price | `ios.purchasing` | `purchasePrice` | Nested under `ios` |
| Device Name | *(top-level)* | `name` + `enforceName: true` | Can also use Classic API MDM command |

---

## Key Differences: Computer vs Mobile Device

| Aspect | Computer (v3) | Mobile Device (v2) |
|---|---|---|
| User/Location section name | `userAndLocation` | `location` |
| Full Name key | `realname` | `realName` (capital N) |
| Email key | `email` | `emailAddress` |
| Phone key | `phone` | `phoneNumber` |
| Asset Tag location | `general.assetTag` | top-level `assetTag` |
| Purchasing location | top-level `purchasing` | `ios.purchasing` |
| Device Name | N/A | top-level `name` + `enforceName` |

---

## Computer Lookup

**Endpoint:** `GET /api/v1/computers-inventory`
**Query params:** `section=GENERAL&filter=hardware.serialNumber=={serial}`
**Purpose:** Look up computer ID by serial number

---

## Mobile Device Lookup

**Endpoint:** `GET /api/v2/mobile-devices`
**Query params:** `section=GENERAL&filter=serialNumber=={serial}`
**Purpose:** Look up mobile device ID by serial number

---

## iOS Device Name (MDM Command) — not used by MUT

**Endpoint:** `POST /JSSResource/mobiledevicecommands/command/DeviceName/{name}/id/{id}`
**API:** Classic API
**Purpose:** Send MDM command to rename an iOS device

MUT sets device names via the v2 mobile device PATCH endpoint (`name` + `enforceName: true`). This Classic API endpoint is documented here for reference only.

---

## Authentication

**Endpoint:** `POST /api/oauth/token`
**Grant type:** `client_credentials`
**Token lifetime:** ~1800s (30 min), no refresh tokens — must re-request

**Invalidate:** `POST /api/v1/auth/invalidate-token`