import SwiftUI

struct UpdateProgressView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView(value: 0.0, total: 1.0)
                .progressViewStyle(.linear)
                .frame(maxWidth: 400)

            Text("Processing updates...")
                .font(.headline)

            Text("0 of \(appViewModel.updateOperations.count) completed")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
