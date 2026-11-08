/// What the learner already believes about a link, shown in the picker: the browser is
/// pre-highlighted and "remember" is pre-ticked, so one Return accepts the learned rule.
/// Nothing is applied without that confirmation.
public struct PickerHint: Equatable, Sendable {
    public var target: BrowserTarget
    public var rule: Rule
    public var label: String

    /// Lower bar than the Suggestions inbox (5): two consistent picks, on any links of the
    /// same domain, are enough to *offer* a rule, because it's only applied on confirmation.
    public static let config = SuggestionConfig(minSupport: 2)

    /// The first suggestion that would open `key` (from `sourceApp`) in a browser.
    public static func find(for key: URLKey, sourceApp: String?, in suggestions: [Suggestion])
        -> PickerHint?
    {
        for s in suggestions {
            guard case .open(let target) = s.action,
                s.sourceAppBundleID == nil || s.sourceAppBundleID == sourceApp,
                s.pattern.matches(key)
            else { continue }
            let label = "Always use this for \(s.pattern) (picked \(Int(s.support.rounded()))×)"
            return PickerHint(target: target, rule: s.makeRule(), label: label)
        }
        return nil
    }
}
