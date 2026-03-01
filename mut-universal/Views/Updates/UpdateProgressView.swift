import SwiftUI

struct UpdateProgressView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = UpdateProgressViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if viewModel.isRunning {
                ProgressView(value: viewModel.progress) {
                    Text("Processing updates...")
                        .font(.headline)
                } currentValueLabel: {
                    Text("\(viewModel.completedOperations) of \(viewModel.totalOperations) completed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .progressViewStyle(.linear)
                .frame(maxWidth: 400)
            } else if !viewModel.results.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Processing Complete")
                    .font(.title2.bold())
            }

            if !viewModel.results.isEmpty {
                HStack(spacing: 24) {
                    Label("\(viewModel.successCount) succeeded", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("\(viewModel.failureCount) failed", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
                .font(.headline)
            }

            if !viewModel.isRunning && !viewModel.results.isEmpty {
                Button {
                    appViewModel.navigateTo(.updateResults)
                } label: {
                    Text("View Results")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .task {
            guard let apiClient = appViewModel.apiClient else { return }
            await viewModel.runUpdates(
                operations: appViewModel.updateOperations,
                deviceType: appViewModel.selectedDeviceType,
                apiClient: apiClient
            )
            appViewModel.updateResults = viewModel.results
        }
    }
}
