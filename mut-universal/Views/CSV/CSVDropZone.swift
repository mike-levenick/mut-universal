import SwiftUI
import UniformTypeIdentifiers
import OSLog

struct CSVDropZone: View {
    var onFileSelected: (URL) -> Void

    @State private var isTargeted = false
    @State private var showFileImporter = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(isTargeted ? Color.accentColor : .secondary)

            Text("Drop a CSV file here or click to browse")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button("Choose CSV File") {
                showFileImporter = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.accentColor.opacity(0.05) : Color.clear)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            showFileImporter = true
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            let ext = url.pathExtension.lowercased()
            guard ext == "csv" || ext == "txt" else { return false }
            onFileSelected(url)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    onFileSelected(url)
                }
            case .failure(let error):
                Logger.csv.error("File import failed: \(error.localizedDescription)")
            }
        }
    }
}
