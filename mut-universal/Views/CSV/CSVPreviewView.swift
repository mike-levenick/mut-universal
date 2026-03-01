import SwiftUI

struct CSVPreviewView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            if let csvData = appViewModel.csvData {
                VStack(spacing: 16) {
                    summaryHeader(csvData: csvData)

                    previewTable(csvData: csvData)

                    actionButtons
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "doc.questionmark",
                    description: Text("No CSV data available for preview.")
                )
            }
        }
        .frame(maxWidth: 800)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbar: some View {
        HStack {
            Button {
                appViewModel.navigateTo(.csvImport)
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)

            Spacer()

            Text("Preview Updates")
                .font(.title2.bold())

            Spacer()

            Color.clear
                .frame(width: 60)
        }
        .padding()
        .background(.bar)
    }

    private func summaryHeader(csvData: CSVData) -> some View {
        HStack {
            Image(systemName: "list.bullet.clipboard")
                .font(.title2)
                .foregroundStyle(.tint)

            Text("\(appViewModel.updateOperations.count) updates to \(appViewModel.selectedDeviceType.rawValue)")
                .font(.headline)

            Spacer()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
    }

    private func previewTable(csvData: CSVData) -> some View {
        let mappedColumns = appViewModel.columnMapping.sorted(by: { $0.key < $1.key })

        return ScrollView([.horizontal, .vertical]) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text(csvData.identifierHeader)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    ForEach(mappedColumns, id: \.key) { _, field in
                        Text(field.displayName)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                    .gridCellColumns(1 + mappedColumns.count)

                ForEach(Array(csvData.rows.prefix(100).enumerated()), id: \.offset) { _, row in
                    GridRow {
                        Text(row[0])
                            .fontWeight(.medium)

                        ForEach(mappedColumns, id: \.key) { columnIndex, _ in
                            Text(columnIndex < row.count ? row[columnIndex] : "")
                        }
                    }
                }
            }
            .padding()
        }
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
    }

    private var actionButtons: some View {
        HStack {
            Button("Back") {
                appViewModel.navigateTo(.csvImport)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()

            Button {
                appViewModel.navigateTo(.updateProgress)
            } label: {
                Text("Run Updates")
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
