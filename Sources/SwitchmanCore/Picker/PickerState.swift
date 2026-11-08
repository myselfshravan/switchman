/// Keyboard behaviour of the browser picker, kept out of the UI so it can be tested.
public struct PickerState: Sendable {
    public enum Key: Equatable, Sendable {
        /// 1-based, as printed on the key.
        case number(Int)
        case up, down, confirm, cancel, toggleRemember
    }

    public enum Outcome: Equatable, Sendable {
        case pick(index: Int, remember: Bool)
        case cancel
    }

    public let count: Int
    /// The browser the learner suggests, if any: highlighted first, with "remember" pre-ticked.
    public let suggested: Int?
    public private(set) var highlighted = 0
    /// Set once the user toggles the checkbox; until then it follows the suggestion.
    private var explicitRemember: Bool?

    public init(count: Int, suggested: Int? = nil) {
        self.count = count
        self.suggested = suggested.flatMap { (0..<count).contains($0) ? $0 : nil }
        highlighted = self.suggested ?? 0
    }

    /// What the checkbox shows. The pre-tick belongs to the suggested browser only, so
    /// picking a different one never creates a rule the user didn't ask for.
    public var remember: Bool { remember(for: highlighted) }

    /// Whether picking `index` (by click, number or Return) should create a rule.
    public func remember(for index: Int) -> Bool {
        explicitRemember ?? (index == suggested)
    }

    /// Applies `key`; returns an outcome when the picker should close.
    public mutating func handle(_ key: Key) -> Outcome? {
        switch key {
        case .cancel:
            return .cancel
        case .toggleRemember:
            explicitRemember = !remember
            return nil
        case .number(let n) where (1...min(count, 9)).contains(n):
            return .pick(index: n - 1, remember: remember(for: n - 1))
        case .confirm where count > 0:
            return .pick(index: highlighted, remember: remember)
        case .up where count > 0:
            highlighted = (highlighted + count - 1) % count
            return nil
        case .down where count > 0:
            highlighted = (highlighted + 1) % count
            return nil
        default:
            return nil
        }
    }
}

extension Rule {
    /// The rule "Remember for <domain>" in the picker creates.
    public static func remembering(_ key: URLKey, opensIn target: BrowserTarget) -> Rule {
        Rule(pattern: .hostWildcard("*." + key.registrableDomain), action: .open(target))
    }
}
