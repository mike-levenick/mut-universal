import SwiftUI

struct UpdateResultsView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var filterMode: FilterMode = .all

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case succeeded = "Succeeded"
        case failed = "Failed"
    }

    private var results: [UpdateResult] {
        appViewModel.updateResults
    }

    private var filteredResults: [UpdateResult] {
        switch filterMode {
        case .all:
            results
        case .succeeded:
            results.filter { if case .success = $0.status { true } else { false } }
        case .failed:
            results.filter { if case .failed = $0.status { true } else { false } }
        }
    }

    private var successCount: Int {
        results.filter { if case .success = $0.status { true } else { false } }.count
    }

    private var failureCount: Int {
        results.filter { if case .failed = $0.status { true } else { false } }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            summaryBanner
            filterBar
            resultsList
            bottomBar
        }
        .frame(maxWidth: 800)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbar: some View {
        HStack {
            Text("Update Results")
                .font(.title2.bold())
            Spacer()
        }
        .padding()
        .background(.bar)
    }

    private var summaryBanner: some View {
        HStack(spacing: 24) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(successCount) succeeded")
            }
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("\(failureCount) failed")
            }
            Spacer()
            Text("\(results.count) total")
                .foregroundStyle(.secondary)
        }
        .font(.headline)
        .padding()
    }

    private var filterBar: some View {
        Picker("Filter", selection: $filterMode) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var resultsList: some View {
        List(filteredResults) { result in
            HStack {
                Image(systemName: statusIcon(for: result.status))
                    .foregroundStyle(statusColor(for: result.status))

                Text(result.identifier)
                    .fontWeight(.medium)

                Spacer()

                Text(statusText(for: result.status))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Button {
                appViewModel.startOver()
            } label: {
                Text("Start Over")
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }

    private func statusIcon(for status: UpdateResult.Status) -> String {
        switch status {
        case .success: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        case .skipped: "minus.circle.fill"
        }
    }

    private func statusColor(for status: UpdateResult.Status) -> Color {
        switch status {
        case .success: .green
        case .failed: .red
        case .skipped: .orange
        }
    }

    private func statusText(for status: UpdateResult.Status) -> String {
        switch status {
        case .success: "Success"
        case .failed(let error): error
        case .skipped(let reason): reason
        }
    }
}
