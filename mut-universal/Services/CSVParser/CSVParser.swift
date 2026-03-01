import Foundation
import OSLog

nonisolated struct CSVParser: Sendable {

    func parse(fileURL: URL) throws -> CSVData {
        let accessed = fileURL.startAccessingSecurityScopedResource()
        defer {
            if accessed { fileURL.stopAccessingSecurityScopedResource() }
        }

        Logger.csv.info("Parsing CSV from file: \(fileURL.lastPathComponent)")

        let content: String
        do {
            content = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            Logger.csv.error("Failed to read file: \(error.localizedDescription)")
            throw MUTError.csvParsingFailed(row: 0, detail: "Could not read file: \(error.localizedDescription)")
        }

        return try parse(string: content)
    }

    func parse(string: String) throws -> CSVData {
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Logger.csv.error("CSV is empty")
            throw MUTError.csvEmpty
        }

        let allRows = try parseRFC4180(string)

        guard let headerRow = allRows.first, !headerRow.allSatisfy({ $0.isEmpty }) else {
            Logger.csv.error("CSV missing header")
            throw MUTError.csvMissingHeader
        }

        let headers = headerRow.map { $0.trimmingCharacters(in: .whitespaces) }
        let expectedColumns = headers.count

        var dataRows: [[String]] = []
        for (index, row) in allRows.dropFirst().enumerated() {
            let trimmed = row.map { $0.trimmingCharacters(in: .whitespaces) }

            // Skip completely empty rows
            if trimmed.allSatisfy({ $0.isEmpty }) {
                continue
            }

            if trimmed.count != expectedColumns {
                let rowNumber = index + 2 // 1-indexed, header is row 1
                Logger.csv.error("Row \(rowNumber) has \(trimmed.count) columns, expected \(expectedColumns)")
                throw MUTError.csvInvalidRowCount(expected: expectedColumns, actual: trimmed.count, row: rowNumber)
            }

            dataRows.append(trimmed)
        }

        Logger.csv.info("Parsed \(dataRows.count) data rows with \(expectedColumns) columns")
        return CSVData(headers: headers, rows: dataRows)
    }

    // MARK: - RFC 4180 Parser

    private func parseRFC4180(_ input: String) throws -> [[String]] {
        var rows: [[String]] = []
        var currentField = ""
        var currentRow: [String] = []
        var inQuotes = false
        var i = input.startIndex

        while i < input.endIndex {
            let char = input[i]

            if inQuotes {
                if char == "\"" {
                    let next = input.index(after: i)
                    if next < input.endIndex && input[next] == "\"" {
                        // Escaped quote
                        currentField.append("\"")
                        i = input.index(after: next)
                    } else {
                        // End of quoted field
                        inQuotes = false
                        i = input.index(after: i)
                    }
                } else {
                    currentField.append(char)
                    i = input.index(after: i)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                    i = input.index(after: i)
                } else if char == "," {
                    currentRow.append(currentField)
                    currentField = ""
                    i = input.index(after: i)
                } else if char == "\r\n" || char == "\r" || char == "\n" {
                    // Swift treats \r\n as a single Character (extended grapheme cluster),
                    // so we match all newline variants in one branch.
                    currentRow.append(currentField)
                    currentField = ""
                    rows.append(currentRow)
                    currentRow = []
                    i = input.index(after: i)
                } else {
                    currentField.append(char)
                    i = input.index(after: i)
                }
            }
        }

        // Handle last field/row (no trailing newline)
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows
    }
}
