import SwiftUI

struct ColumnMappingView: View {
    let csvData: CSVData
    let availableFields: [UpdatableField]
    @Binding var columnMapping: [Int: UpdatableField]

    var body: some View {
        Section("Column Mapping") {
            ForEach(Array(csvData.headers.enumerated()), id: \.offset) { index, header in
                if index == 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(header)
                                .fontWeight(.medium)
                            Text("(Identifier)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        sampleValues(for: index)
                    }
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(header)
                                .fontWeight(.medium)

                            sampleValues(for: index)
                        }

                        Spacer()

                        Picker("", selection: fieldBinding(for: index)) {
                            Text("Skip").tag(Optional<UpdatableField>.none)
                            ForEach(availableFields) { field in
                                Text(field.displayName).tag(Optional(field))
                            }
                        }
                        .frame(width: 180)
                    }
                }
            }
        }
    }

    private func fieldBinding(for index: Int) -> Binding<UpdatableField?> {
        Binding(
            get: { columnMapping[index] },
            set: { newValue in
                if let field = newValue {
                    columnMapping[index] = field
                } else {
                    columnMapping.removeValue(forKey: index)
                }
            }
        )
    }

    @ViewBuilder
    private func sampleValues(for columnIndex: Int) -> some View {
        let samples = csvData.rows.prefix(3).compactMap { row -> String? in
            guard columnIndex < row.count else { return nil }
            let value = row[columnIndex]
            return value.isEmpty ? nil : value
        }

        if !samples.isEmpty {
            Text(samples.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }
}
