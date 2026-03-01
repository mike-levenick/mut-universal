import SwiftUI

struct UpdateResultsView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Updates Complete")
                .font(.largeTitle.bold())

            Text("Results summary will be displayed here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
