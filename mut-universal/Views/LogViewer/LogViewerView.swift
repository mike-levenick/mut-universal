import SwiftUI
import UniformTypeIdentifiers

struct LogViewerView: View {
    @Environment(LogStore.self) private var logStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategories: Set<LogCategory> = Set(LogCategory.allCases)
    @State private var minimumLevel: LogLevelFilter = .all
    @State private var searchText = ""
    @State private var showExporter = false
    @State private var exportDocument: LogDocument?

    enum LogLevelFilter: String, CaseIterable {
        case all = "All"
        case warning = "Warning+"
        case error = "Error"
    }

    private var filteredEntries: [LogEntry] {
        logStore.entries.filter { entry in
            selectedCategories.contains(entry.category)
                && matchesLevel(entry.level)
                && (searchText.isEmpty || entry.message.localizedCaseInsensitiveContains(searchText))
        }
    }

    private func matchesLevel(_ level: LogLevel) -> Bool {
        switch minimumLevel {
        case .all: true
        case .warning: level >= .warning
        case .error: level >= .error
        }
    }

    private var errorCount: Int {
        logStore.entries.filter { $0.level == .error }.count
    }

    private var warningCount: Int {
        logStore.entries.filter { $0.level == .warning }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            filterBar
            logList
            statusBar
        }
        .frame(minWidth: 600, idealWidth: 800, minHeight: 400, idealHeight: 600)
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .plainText,
            defaultFilename: exportFilename()
        ) { _ in }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Text("Logs")
                .font(.title2.bold())

            Spacer()

            Button {
                exportDocument = LogDocument(text: logStore.exportText())
                showExporter = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Filters

    private var filterBar: some View {
        VStack(spacing: 8) {
            // Category toggles
            HStack(spacing: 6) {
                ForEach(LogCategory.allCases) { category in
                    Toggle(category.displayName, isOn: categoryBinding(for: category))
                        .toggleStyle(.button)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                // Level filter
                Picker("Level", selection: $minimumLevel) {
                    ForEach(LogLevelFilter.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 250)

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Log List

    private var logList: some View {
        ScrollViewReader { proxy in
            List(filteredEntries) { entry in
                logRow(entry)
                    .id(entry.id)
            }
            .listStyle(.plain)
            .onChange(of: logStore.entries.count) {
                if let lastEntry = filteredEntries.last {
                    withAnimation {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func logRow(_ entry: LogEntry) -> some View {
        HStack(spacing: 8) {
            Text(formatTime(entry.timestamp))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            Image(systemName: entry.level.systemImage)
                .foregroundStyle(entry.level.color)
                .font(.caption)

            Text(entry.category.displayName)
                .font(.caption)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))

            Text(entry.message)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(2)
        }
        .padding(.vertical, 2)
        .listRowBackground(rowBackground(for: entry.level))
    }

    private func rowBackground(for level: LogLevel) -> Color? {
        switch level {
        case .error: Color.red.opacity(0.08)
        case .warning: Color.orange.opacity(0.06)
        case .info: nil
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Text("\(filteredEntries.count) entries")
                .foregroundStyle(.secondary)

            if errorCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("\(errorCount)")
                }
                .font(.caption)
            }

            if warningCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("\(warningCount)")
                }
                .font(.caption)
            }

            Spacer()

            Button("Clear") {
                logStore.clear()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Helpers

    private func categoryBinding(for category: LogCategory) -> Binding<Bool> {
        Binding(
            get: { selectedCategories.contains(category) },
            set: { isOn in
                if isOn {
                    selectedCategories.insert(category)
                } else if selectedCategories.count > 1 {
                    selectedCategories.remove(category)
                }
            }
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }

    private func exportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "MUT-Logs-\(formatter.string(from: Date.now)).txt"
    }
}

// MARK: - Log Document for Export

struct LogDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    let text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
