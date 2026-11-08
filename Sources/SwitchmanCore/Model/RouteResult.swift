public enum RouteResult: Hashable, Sendable {
    case open(BrowserTarget, reason: Reason)
    case ask(reason: Reason)

    public enum Reason: Hashable, Sendable {
        /// `index` is the rule's 0-based position in the rule list.
        case rule(index: Int, Rule)
        case noRule
        case forcedByModifier
    }
}

extension RouteResult {
    /// One line such as `Brave — rule #4 github.com/acme/*, source: Slack`.
    /// `appName` turns a bundle ID into a display name; the shell passes installed app names.
    public func explanation(appName: (String) -> String = { $0 }) -> String {
        switch self {
        case .open(let target, let reason):
            let profile = target.profileDirectory.map { " (\($0))" } ?? ""
            return "\(appName(target.bundleID))\(profile) — \(reason.explanation(appName: appName))"
        case .ask(.rule(let index, let rule)):
            return "Ask — rule #\(index + 1) \(rule.pattern) is always-ask"
        case .ask(let reason):
            return "Ask — \(reason.explanation(appName: appName))"
        }
    }
}

extension RouteResult.Reason {
    fileprivate func explanation(appName: (String) -> String) -> String {
        switch self {
        case .rule(let index, let rule):
            let source = rule.sourceAppBundleID.map { ", source: \(appName($0))" } ?? ""
            return "rule #\(index + 1) \(rule.pattern)\(source)"
        case .noRule: return "no rule matches"
        case .forcedByModifier: return "Option key held"
        }
    }
}
