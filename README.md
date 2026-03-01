# MUT — Mass Update Tool

A macOS app for Jamf Pro administrators to make mass updates to managed devices, users, and configurations via CSV upload.

## About

MUT (Mass Update Tool) lets Jamf admins skip the tedious work of updating records one-by-one in the Jamf Pro web console. Upload a CSV file with identifiers and values, and MUT applies the changes in bulk via the Jamf Pro API.

### What You Can Update

- **iOS device inventory** — asset tags, device names, and other inventory fields
- **macOS device inventory** — asset tags, device names, and other inventory fields
- **User records** — user attributes managed in Jamf Pro
- **PreStage Enrollments** — assign devices to PreStage enrollment configurations
- **Static group membership** — add or remove devices/users from static groups

## Requirements

- macOS 14 (Sonoma) or later
- A Jamf Pro instance with API access
- A Jamf Pro user account with appropriate permissions for the updates you want to perform

## How It Works

1. **Authenticate** — Enter your Jamf Pro URL and credentials
2. **Choose update type** — Select what you're updating (devices, users, groups, etc.)
3. **Upload CSV** — Select a `.csv` file with identifiers in the first column and update values in subsequent columns
4. **Preview** — Review the parsed data before committing
5. **Run updates** — MUT sends the updates to Jamf Pro and reports results

### CSV Format

CSV files should follow this structure:

```csv
Serial Number,Asset Tag,Building
C02X12345,ASSET-001,Main Office
C02X67890,ASSET-002,Remote
```

- First row: header (column names)
- First column: identifier (serial number, asset tag, username, etc.)
- Remaining columns: values to update

## Building from Source

This project uses Swift Package Manager for dependencies. Xcode will resolve packages automatically on first open.

```bash
# Command line build
xcodebuild -scheme MUT -configuration Debug build
```

## License

TBD

## History

MUT is a ground-up rewrite of the original [MUT app](https://github.com/mike-levenick/mut), rebuilt with SwiftUI and modern Swift concurrency.
