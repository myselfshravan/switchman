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
    public private(set) var highlighted = 0
    public private(set) var remember = false

    public init(count: Int) {
        self.count = count
    }

    /// Applies `key`; returns an outcome when the picker should close.
    public mutating func handle(_ key: Key) -> Outcome? {
        switch key {
        case .cancel:
            return .cancel
        case .toggleRemember:
            remember.toggle()
            return nil
        case .number(let n) where (1...min(count, 9)).contains(n):
            return .pick(index: n - 1, remember: remember)
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
