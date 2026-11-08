import SwitchmanCore

/// `switchman rules list|validate`
func rules(_ arguments: Arguments) throws {
    let rules = try arguments.loadRules()
    switch arguments.positional.first {
    case "list":
        for (index, rule) in rules.enumerated() {
            print("#\(index + 1)  \(rule.summary)")
        }
    case "validate":
        let problems = RulesFile.problems(in: rules)
        guard problems.isEmpty else { throw CLIError.data(problems.joined(separator: "\n")) }
        print("\(rules.count) rules OK")
    default:
        throw CLIError.usage("rules needs list or validate")
    }
}

extension Rule {
    /// `github.com/acme/*  → com.brave.Browser  from com.tinyspeck.slackmacgap`
    fileprivate var summary: String {
        var parts = ["\(pattern)", "→ \(action.summary)"]
        if let sourceAppBundleID { parts.append("from \(sourceAppBundleID)") }
        if !enabled { parts.append("(disabled)") }
        return parts.joined(separator: "  ")
    }
}

extension RuleAction {
    fileprivate var summary: String {
        switch self {
        case .open(let target): target.bundleID + (target.profileDirectory.map { " (\($0))" } ?? "")
        case .alwaysAsk: "ask"
        }
    }
}
