import Foundation

/// The `rules.json` format: `{"version": 1, "rules": [ ...ordered rules... ]}`.
/// Pretty-printed with sorted keys so hand edits and git diffs stay small.
public enum RulesFile {
    public static let currentVersion = 1

    public enum Error: Swift.Error, Equatable {
        case unsupportedVersion(Int)
    }

    private struct Contents: Codable {
        var version: Int
        var rules: [Rule]
    }

    public static func decode(_ data: Data) throws -> [Rule] {
        let contents = try JSONDecoder().decode(Contents.self, from: data)
        guard contents.version <= currentVersion else {
            throw Error.unsupportedVersion(contents.version)
        }
        return contents.rules
    }

    public static func encode(_ rules: [Rule]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(Contents(version: currentVersion, rules: rules))
        data.append(contentsOf: "\n".utf8)
        return data
    }

    /// Human-readable problems, e.g. `rule #2: invalid regex …`. Empty when every rule is valid.
    public static func problems(in rules: [Rule]) -> [String] {
        rules.enumerated().compactMap { index, rule in
            rule.pattern.validationError.map { "rule #\(index + 1): \($0)" }
        }
    }
}
