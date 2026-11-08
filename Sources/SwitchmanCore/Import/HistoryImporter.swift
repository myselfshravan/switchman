import Foundation
import SQLite3

/// Seeds the learner from Chromium browser history: every visited URL becomes an `.imported`
/// decision for the browser/profile it was visited in, weighted `log2(1 + visit_count)`.
public enum HistoryImporter {
    public enum Error: Swift.Error, Equatable {
        case sqlite(String)
    }

    /// The `History` database of each profile under a browser's user-data directory.
    public static func histories(userDataDirectory root: URL, bundleID: String)
        -> [(target: BrowserTarget, history: URL)]
    {
        let localState = root.appendingPathComponent("Local State")
        var profiles =
            (try? Data(contentsOf: localState)).flatMap {
                try? ChromiumProfiles.parse(localState: $0)
            }
            ?? []
        if profiles.isEmpty { profiles = [ChromiumProfile(directory: "Default", name: "Default")] }
        let targets = ChromiumProfiles.targets(bundleID: bundleID, profiles: profiles)
        let all = profiles.count > 1 ? Array(zip(targets, profiles)) : [(targets[0], profiles[0])]
        return all.map { target, profile in
            (
                target,
                root.appendingPathComponent(profile.directory).appendingPathComponent("History")
            )
        }
        .filter { FileManager.default.fileExists(atPath: $0.1.path) }
    }

    /// Reads a copy of `history` (the original is locked while the browser runs).
    public static func decisions(
        history: URL, target: BrowserTarget, date: Date, suffixes: PublicSuffixList = .bundled
    ) throws -> [Decision] {
        let copy = FileManager.default.temporaryDirectory
            .appendingPathComponent("switchman-history-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: history, to: copy)
        defer { try? FileManager.default.removeItem(at: copy) }
        return try rows(in: copy).compactMap { url, visits in
            URLKey(url, suffixes: suffixes).map {
                Decision(
                    date: date, key: $0, chosen: target, kind: .imported,
                    weight: Decision.importedWeight(visitCount: visits))
            }
        }
    }

    private static func rows(in database: URL) throws -> [(String, Int)] {
        var db: OpaquePointer?
        defer { sqlite3_close(db) }
        guard sqlite3_open_v2(database.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            throw Error.sqlite(String(cString: sqlite3_errmsg(db)))
        }
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        let sql = "SELECT url, visit_count FROM urls WHERE visit_count > 0 ORDER BY id"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw Error.sqlite(String(cString: sqlite3_errmsg(db)))
        }
        var rows: [(String, Int)] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let text = sqlite3_column_text(statement, 0) else { continue }
            rows.append((String(cString: text), Int(sqlite3_column_int64(statement, 1))))
        }
        return rows
    }
}
