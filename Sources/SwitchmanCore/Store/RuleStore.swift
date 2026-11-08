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

    /// Adds `rule` at the top, so it takes precedence over older, broader rules. An any-source
    /// rule goes below the source-scoped rules at the top, so it can't shadow them.
    public mutating func add(_ rule: Rule) throws {
        var updated = rules
        let index =
            rule.sourceAppBundleID == nil
            ? updated.firstIndex { $0.sourceAppBundleID == nil } ?? updated.endIndex : 0
        updated.insert(rule, at: index)
        try save(updated)
    }

    /// Suggestions the user rejected, so the learner never proposes them again.
    public func loadRejected() -> Set<SuggestionShape> {
        guard let data = try? Data(contentsOf: location.rejected) else { return [] }
        return (try? JSONDecoder().decode(Set<SuggestionShape>.self, from: data)) ?? []
    }

    public func reject(_ shape: SuggestionShape) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let all = loadRejected().union([shape]).sorted { "\($0)" < "\($1)" }
        try FileManager.default.createDirectory(
            at: location.base, withIntermediateDirectories: true)
        try encoder.encode(all).write(to: location.rejected, options: .atomic)
    }
}
