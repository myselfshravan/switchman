import SwiftUI
import SwitchmanCore

/// Seeds suggestions from Chrome/Brave/… history. Read-only, local, and nothing is applied
/// until the user accepts a suggestion.
struct ImportTab: View {
    let model: AppModel
    @State private var running = false
    @State private var report = ""

    private var installed: [(ChromiumBrowser, URL)] {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return ChromiumBrowser.known.map { ($0, support.appendingPathComponent($0.userDataPath)) }
            .filter { FileManager.default.fileExists(atPath: $0.1.path) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                "Learn from where you already browse: each profile's history counts as choices "
                    + "for that browser. History is read from a temporary copy and never leaves your Mac."
            )
            .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button(running ? "Importing…" : "Import from \(names)") { run() }
                    .disabled(running || installed.isEmpty)
                Text(report).font(.caption).foregroundStyle(.secondary)
            }
            List(model.importedSuggestions, id: \.self) {
                SuggestionRow(model: model, suggestion: $0)
            }
        }
    }

    private var names: String {
        installed.isEmpty ? "browsers" : installed.map(\.0.name).joined(separator: ", ")
    }

    private func run() {
        running = true
        let sources = installed
        let rules = model.store.rules
        let rejected = model.store.loadRejected()
        Task {
            let (suggestions, count) = await Task.detached {
                var decisions: [Decision] = []
                for (browser, root) in sources {
                    for (target, history) in HistoryImporter.histories(
                        userDataDirectory: root, bundleID: browser.bundleID)
                    {
                        decisions +=
                            (try? HistoryImporter.decisions(
                                history: history, target: target, date: Date())) ?? []
                    }
                }
                let suggestions = SuggestionEngine.suggest(
                    decisions: decisions, existingRules: rules, rejected: rejected)
                return (suggestions, decisions.count)
            }.value
            model.importedSuggestions = suggestions
            report = "\(count) URLs read, \(suggestions.count) suggestions"
            running = false
        }
    }
}
