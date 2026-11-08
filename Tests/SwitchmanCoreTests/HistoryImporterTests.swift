import Foundation
import SQLite3
import SwitchmanCore
import Testing

/// Writes a minimal Chromium `History` database with the given `(url, visit_count)` rows.
func makeHistory(at url: URL, rows: [(String, Int)]) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    var db: OpaquePointer?
    guard sqlite3_open(url.path, &db) == SQLITE_OK else { throw CocoaError(.fileWriteUnknown) }
    defer { sqlite3_close(db) }
    let inserts = rows.map { "INSERT INTO urls(url, visit_count) VALUES ('\($0.0)', \($0.1));" }
    let sql = """
        CREATE TABLE urls(id INTEGER PRIMARY KEY, url LONGVARCHAR, title LONGVARCHAR,
                          visit_count INTEGER DEFAULT 0 NOT NULL);
        \(inserts.joined(separator: "\n"))
        """
    guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
        throw CocoaError(.fileWriteUnknown)
    }
}

@Suite struct HistoryImporterTests {
    let dir: TemporaryDirectory
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws { dir = try TemporaryDirectory() }

    @Test func mapsRowsToWeightedImportedDecisions() throws {
        let history = dir.url.appendingPathComponent("History")
        try makeHistory(
            at: history,
            rows: [
                ("https://github.com/acme/api?tab=1", 7),
                ("https://www.youtube.com/watch?v=x", 1),
                ("chrome://settings", 40),
                ("https://unvisited.com", 0),
            ])
        let decisions = try HistoryImporter.decisions(history: history, target: brave, date: now)
        #expect(
            decisions == [
                Decision(
                    date: now, key: key("https://github.com/acme/api"), chosen: brave,
                    kind: .imported, weight: 3),
                Decision(
                    date: now, key: key("https://youtube.com/watch"), chosen: brave,
                    kind: .imported, weight: 1),
            ])
    }

    @Test func readsACopySoTheOriginalIsUntouched() throws {
        let history = dir.url.appendingPathComponent("History")
        try makeHistory(at: history, rows: [("https://a.com", 1)])
        let before = try Data(contentsOf: history)
        _ = try HistoryImporter.decisions(history: history, target: brave, date: now)
        #expect(try Data(contentsOf: history) == before)
    }

    @Test func missingOrInvalidDatabaseThrows() throws {
        let missing = dir.url.appendingPathComponent("nope/History")
        #expect(throws: (any Error).self) {
            try HistoryImporter.decisions(history: missing, target: brave, date: now)
        }
        let junk = dir.url.appendingPathComponent("History")
        try Data("not sqlite".utf8).write(to: junk)
        #expect(throws: HistoryImporter.Error.self) {
            try HistoryImporter.decisions(history: junk, target: brave, date: now)
        }
    }

    @Test func findsHistoryPerProfileFromLocalState() throws {
        let root = dir.url.appendingPathComponent("Google/Chrome")
        try makeHistory(at: root.appendingPathComponent("Default/History"), rows: [])
        try makeHistory(at: root.appendingPathComponent("Profile 1/History"), rows: [])
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("Profile 2"), withIntermediateDirectories: true)
        try Data(
            #"{"profile":{"info_cache":{"Default":{"name":"Me"},"Profile 1":{"name":"Work"},"Profile 2":{"name":"Empty"}}}}"#
                .utf8
        ).write(to: root.appendingPathComponent("Local State"))

        let found = HistoryImporter.histories(
            userDataDirectory: root, bundleID: "com.google.Chrome")
        #expect(found.map(\.target.profileDirectory) == ["Default", "Profile 1"])
        #expect(found.allSatisfy { FileManager.default.fileExists(atPath: $0.history.path) })
    }

    @Test func singleProfileBrowserWithoutLocalStateUsesDefault() throws {
        let root = dir.url.appendingPathComponent("BraveSoftware/Brave-Browser")
        try makeHistory(at: root.appendingPathComponent("Default/History"), rows: [])
        let found = HistoryImporter.histories(
            userDataDirectory: root, bundleID: "com.brave.Browser")
        #expect(found.map(\.target) == [brave])
        #expect(found.first?.history.path.hasSuffix("Default/History") == true)
    }

    @Test func importFeedsTheSameSuggestionEngine() throws {
        let work = dir.url.appendingPathComponent("brave/History")
        let home = dir.url.appendingPathComponent("chrome/History")
        try makeHistory(
            at: work, rows: [("https://notion.so/acme/a", 30), ("https://notion.so/acme/b", 12)])
        try makeHistory(at: home, rows: [("https://youtube.com/watch", 200)])
        let decisions =
            try HistoryImporter.decisions(history: work, target: brave, date: now)
            + HistoryImporter.decisions(history: home, target: chrome, date: now)
        let suggestions = SuggestionEngine.suggest(decisions: decisions, existingRules: [])
        #expect(
            suggestions.map(\.pattern) == [
                .hostWildcard("*.notion.so"), .hostWildcard("*.youtube.com"),
            ])
        #expect(suggestions.allSatisfy { $0.origin == .imported })
        #expect(suggestions.map(\.action) == [.open(brave), .open(chrome)])
    }
}
