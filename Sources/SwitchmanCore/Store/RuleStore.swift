import Foundation

/// Loads and saves `rules.json`. A broken file never wipes the rules in use: `reload()` keeps
/// the last good rules and reports the problem in `lastError`.
public struct RuleStore: Sendable {
    public let location: StoreLocation
    public private(set) var rules: [Rule] = []
    public private(set) var lastError: String?

    public init(location: StoreLocation) {
        self.location = location
    }

    public mutating func reload() {
        let url = location.rules
        guard FileManager.default.fileExists(atPath: url.path) else {
            rules = []
            lastError = nil
            return
        }
        do {
            rules = try RulesFile.decode(Data(contentsOf: url))
            lastError = nil
        } catch {
            lastError = "\(url.path): \(error)"
        }
    }

    public mutating func save(_ rules: [Rule]) throws {
        try FileManager.default.createDirectory(
            at: location.base, withIntermediateDirectories: true)
        try RulesFile.encode(rules).write(to: location.rules, options: .atomic)
        self.rules = rules
        lastError = nil
    }

    /// Adds `rule` at the top, so it takes precedence over older, broader rules.
    public mutating func add(_ rule: Rule) throws {
        try save([rule] + rules)
    }
}
