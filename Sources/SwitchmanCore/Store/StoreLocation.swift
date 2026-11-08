import Foundation

/// Where Switchman keeps its files. Tests and `--home` inject a different base directory.
public struct StoreLocation: Sendable {
    public var base: URL

    public init(base: URL) { self.base = base }

    /// `~/Library/Application Support/Switchman`.
    public static var `default`: StoreLocation {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return StoreLocation(base: support.appendingPathComponent("Switchman", isDirectory: true))
    }

    public var rules: URL { base.appendingPathComponent("rules.json") }
    public var decisions: URL { base.appendingPathComponent("decisions.jsonl") }
}
