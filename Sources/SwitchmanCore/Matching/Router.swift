/// Keyboard modifiers held when the link arrived.
public struct Modifiers: OptionSet, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let option = Modifiers(rawValue: 1 << 0)
}

public enum Router {
    /// Option forces the picker; otherwise the first enabled rule matching the key and source
    /// wins; otherwise ask.
    public static func route(
        _ key: URLKey, sourceApp: String?, rules: [Rule], modifiers: Modifiers = []
    ) -> RouteResult {
        if modifiers.contains(.option) { return .ask(reason: .forcedByModifier) }
        guard let index = rules.firstIndex(where: { $0.matches(key, sourceApp: sourceApp) }) else {
            return .ask(reason: .noRule)
        }
        let rule = rules[index]
        switch rule.action {
        case .open(let target): return .open(target, reason: .rule(index: index, rule))
        case .alwaysAsk: return .ask(reason: .rule(index: index, rule))
        }
    }
}
