import Foundation

/// The slice of URL space a group of decisions belongs to, narrowed level by level.
/// Sibling scopes produced by one split never overlap, so their rules can go in any order.
struct Scope {
    var domain: String
    var host: String?
    var authority: String?
    var hints: [String: String]?
    var path: [String] = []
    /// nil = not split by source; `.some(nil)` = links whose source app was unknown.
    var source: String??

    /// The narrowest pattern that covers exactly this scope.
    var pattern: Pattern {
        if let authority, let hints { return .regex(Self.regex(authority, path, hints)) }
        if let authority, !path.isEmpty {
            return .urlPrefix(([authority] + path).joined(separator: "/") + "/")
        }
        if let host { return .host(host) }
        return .hostWildcard("*." + domain)
    }

    /// `^docs\.google\.com(/[^?]*)?\?authuser=1$` — this authority (and path prefix) with
    /// exactly these hints. Empty hints means "no hint query keys at all".
    private static func regex(_ authority: String, _ path: [String], _ hints: [String: String])
        -> String
    {
        let prefix = ([authority] + path).joined(separator: "/")
        let query = hints.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        let escapedQuery = query.isEmpty ? "" : #"\?"# + escape(query)
        return "^" + escape(prefix) + "(/[^?]*)?" + escapedQuery + "$"
    }

    private static func escape(_ literal: String) -> String {
        NSRegularExpression.escapedPattern(for: literal)
    }
}

/// One way of splitting a mixed group, tried in order: host → hint → path depth → source app.
enum Level: Equatable {
    case host, hint, path(depth: Int), source

    static func all(_ config: SuggestionConfig) -> [Level] {
        [.host, .hint] + (0..<max(0, config.maxPathDepth)).map { .path(depth: $0 + 1) } + [.source]
    }

    /// Partitions `decisions` into narrower scopes. One part means this level can't help.
    func split(_ decisions: [Decision], in scope: Scope) -> [(Scope, [Decision])] {
        switch self {
        case .host:
            return Self.group(decisions, by: \.key.host) { scope.with(\.host, $0) }
        case .hint:
            return Self.group(
                decisions, by: { HintKey(authority: $0.key.authority, hints: $0.key.hints) }
            ) {
                scope.with(\.authority, $0.authority).with(\.hints, $0.hints)
            }
        case .path(let depth):
            let deep = decisions.filter { $0.key.pathSegments.count >= depth }
            return Self.group(deep, by: { [$0.key.authority] + $0.key.pathSegments.prefix(depth) })
            {
                scope.with(\.authority, $0[0]).with(\.path, Array($0.dropFirst()))
            }
        case .source:
            return Self.group(decisions, by: \.sourceAppBundleID) {
                scope.with(\.source, .some($0))
            }
        }
    }

    private struct HintKey: Hashable {
        var authority: String
        var hints: [String: String]
    }

    /// Groups in first-seen order, so results are deterministic.
    private static func group<K: Hashable>(
        _ decisions: [Decision], by key: (Decision) -> K, scope: (K) -> Scope
    ) -> [(Scope, [Decision])] {
        var order: [K] = []
        var groups: [K: [Decision]] = [:]
        for decision in decisions {
            let k = key(decision)
            if groups[k] == nil { order.append(k) }
            groups[k, default: []].append(decision)
        }
        return order.map { (scope($0), groups[$0]!) }
    }
}

extension Scope {
    fileprivate func with<V>(_ keyPath: WritableKeyPath<Scope, V>, _ value: V) -> Scope {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
}
