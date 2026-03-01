import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = CSVImportViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            ScrollView {
                VStack(spacing: 24) {
                    deviceTypePicker

                    if viewModel.csvData == nil {
                        CSVDropZone { url in
                            viewModel.loadCSV(from: url)
                        }
                        .padding(.horizontal)
                    } else {
                        csvLoadedSection
                    }

                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(errorMessage)
                    }

                    if viewModel.csvData != nil {
                        Form {
                            ColumnMappingView(
                                csvData: viewModel.csvData!,
                                availableFields: viewModel.availableFields,
                                columnMapping: $viewModel.columnMapping
                            )
                        }
                        .formStyle(.grouped)
                    }

                    if viewModel.isReadyToPreview {
                        previewButton
                    }
                }
                .padding(.vertical)
            }
        }
        .frame(maxWidth: 800)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbar: some View {
        HStack {
            Text("MUT")
                .font(.title2.bold())

            Spacer()

            Button("Logout") {
                Task {
                    await appViewModel.logout()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.bar)
    }

    private var deviceTypePicker: some View {
        Picker("Device Type", selection: $viewModel.selectedDeviceType) {
            ForEach(DeviceType.allCases) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: viewModel.selectedDeviceType) {
            viewModel.onDeviceTypeChanged()
        }
    }

    private var csvLoadedSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(.tint)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.fileName ?? "CSV File")
                        .fontWeight(.medium)

                    if let csvData = viewModel.csvData {
                        Text("\(csvData.rowCount) rows, \(csvData.columnCount) columns")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button("Remove") {
                    viewModel.clearCSV()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            }
        }
        .padding(.horizontal)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.caption)
                .foregroundStyle(.red)

            Spacer()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        }
        .padding(.horizontal)
    }

    private var previewButton: some View {
        Button {
            if let operations = viewModel.validateAndPreview() {
                appViewModel.csvData = viewModel.csvData
                appViewModel.selectedDeviceType = viewModel.selectedDeviceType
                appViewModel.columnMapping = viewModel.columnMapping
                appViewModel.updateOperations = operations
                appViewModel.navigateTo(.csvPreview)
            }
        } label: {
            Text("Preview Updates")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
    }
}
