import Foundation
import SwitchmanCore

/// `switchman import [--chrome <dir>] [--brave <dir>] …` — dry run: prints the suggestions
/// that browser history would produce. Each option names a known Chromium browser and its
/// user-data directory; with none, every known browser's default directory is read.
func importHistory(_ arguments: Arguments) throws {
    let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[
        0]
    let explicit = arguments.options.filter { $0.key != "home" && !$0.key.hasPrefix("min-") }
    let sources: [(ChromiumBrowser, URL)] =
        explicit.isEmpty
        ? ChromiumBrowser.known.map { ($0, support.appendingPathComponent($0.userDataPath)) }
        : try explicit.sorted { $0.key < $1.key }.map { name, path in
            guard let browser = ChromiumBrowser.named(name) else {
                throw CLIError.usage("unknown browser --\(name)")
            }
            return (browser, URL(fileURLWithPath: path))
        }

    var decisions: [Decision] = []
    for (browser, root) in sources {
        for (target, history) in HistoryImporter.histories(
            userDataDirectory: root, bundleID: browser.bundleID)
        {
            let imported = try HistoryImporter.decisions(
                history: history, target: target, date: Date())
            print("imported \(imported.count) URLs from \(RuleAction.open(target))")
            decisions += imported
        }
    }
    printSuggestions(
        SuggestionEngine.suggest(
            decisions: decisions, existingRules: try arguments.loadRules(),
            rejected: RuleStore(location: arguments.location).loadRejected(),
            config: try arguments.suggestionConfig()))
}
