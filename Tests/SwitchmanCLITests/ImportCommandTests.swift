import Foundation
import Testing

@Suite struct ImportCommandTests {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("switchman-cli-import-\(UUID().uuidString)")
        try makeHistory(
            root.appendingPathComponent("brave/Default/History"),
            [("https://notion.so/acme/a", 40), ("https://github.com/acme/api", 31)])
        try makeHistory(
            root.appendingPathComponent("chrome/Default/History"),
            [("https://youtube.com/watch", 100), ("https://github.com/me/blog", 63)])
    }

    /// Builds a minimal Chromium History database with the system `sqlite3` tool.
    func makeHistory(_ url: URL, _ rows: [(String, Int)]) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let inserts = rows.map { "INSERT INTO urls(url, visit_count) VALUES ('\($0.0)', \($0.1));" }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = [
            url.path,
            "CREATE TABLE urls(id INTEGER PRIMARY KEY, url TEXT, visit_count INTEGER);"
                + inserts.joined(),
        ]
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
    }

    @Test func dryRunPrintsImportedSuggestions() throws {
        defer { try? FileManager.default.removeItem(at: root) }
        let r = try runCLI([
            "import", "--brave", root.appendingPathComponent("brave").path,
            "--chrome", root.appendingPathComponent("chrome").path,
            "--home", root.appendingPathComponent("home").path,
        ])
        #expect(r.status == 0)
        #expect(
            r.stdout == """
                imported 2 URLs from com.brave.Browser
                imported 2 URLs from com.google.Chrome
                suggestions (4):
                  1. *.youtube.com  → com.google.Chrome  (support 6.7, 100%, imported)  e.g. youtube.com/watch
                  2. github.com/me/*  → com.google.Chrome  (support 6, 100%, imported)  e.g. github.com/me/blog
                  3. *.notion.so  → com.brave.Browser  (support 5.4, 100%, imported)  e.g. notion.so/acme/a
                  4. github.com/acme/*  → com.brave.Browser  (support 5, 100%, imported)  e.g. github.com/acme/api

                """)
    }

    @Test func unknownBrowserIsUsageError() throws {
        defer { try? FileManager.default.removeItem(at: root) }
        let r = try runCLI(["import", "--netscape", root.path])
        #expect(r.status == 64)
        #expect(r.stderr.contains("unknown browser --netscape"))
    }
}
