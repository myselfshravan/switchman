/// A rule the learner proposes. The user accepts, edits or rejects it; nothing is applied
/// automatically.
public struct Suggestion: Hashable, Codable, Sendable {
    public var pattern: Pattern
    public var sourceAppBundleID: String?
    public var action: RuleAction
    /// Total decision weight behind the suggestion.
    public var support: Double
    /// Share of `support` that chose the winning browser (for `alwaysAsk`, the best share seen).
    public var confidence: Double
    /// Up to three representative keys, most weighted first.
    public var examples: [URLKey]
    /// `.imported` when every decision behind it came from browser history, else `.learned`.
    public var origin: Origin

    public init(
        pattern: Pattern, sourceAppBundleID: String?, action: RuleAction, support: Double,
        confidence: Double, examples: [URLKey], origin: Origin
    ) {
        self.pattern = pattern
        self.sourceAppBundleID = sourceAppBundleID
        self.action = action
        self.support = support
        self.confidence = confidence
        self.examples = examples
        self.origin = origin
    }

    public var shape: SuggestionShape {
        SuggestionShape(pattern: pattern, sourceAppBundleID: sourceAppBundleID, action: action)
    }

    public func makeRule() -> Rule {
        Rule(pattern: pattern, sourceAppBundleID: sourceAppBundleID, action: action, origin: origin)
    }
}

/// What makes two suggestions "the same" — used to remember rejections.
public struct SuggestionShape: Hashable, Codable, Sendable {
    public var pattern: Pattern
    public var sourceAppBundleID: String?
    public var action: RuleAction

    public init(pattern: Pattern, sourceAppBundleID: String?, action: RuleAction) {
        self.pattern = pattern
        self.sourceAppBundleID = sourceAppBundleID
        self.action = action
    }
}

public struct SuggestionConfig: Sendable {
    public var minSupport: Double
    public var minConfidence: Double
    public var maxPathDepth: Int

    public init(minSupport: Double = 5, minConfidence: Double = 0.9, maxPathDepth: Int = 1) {
        self.minSupport = minSupport
        self.minConfidence = minConfidence
        self.maxPathDepth = maxPathDepth
    }
}

/// An existing rule that the user's corrections keep contradicting.
public struct Disagreement: Hashable, Sendable {
    public var ruleIndex: Int
    public var rule: Rule
    public var count: Int
    /// The browser the user corrected to most often.
    public var chosen: BrowserTarget
    public var examples: [URLKey]

    /// `rule #2 *.atlassian.net disagrees with you 4 times`
    public var summary: String {
        "rule #\(ruleIndex + 1) \(rule.pattern) disagrees with you \(count) time\(count == 1 ? "" : "s")"
    }
}
