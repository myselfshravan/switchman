import SwitchmanCore

/// `switchman suggest [--min-support 5] [--min-confidence 0.9]`
func suggest(_ arguments: Arguments) throws {
    let rules = try arguments.loadRules()
    let decisions = try DecisionLog(location: arguments.location).readAll()
    let suggestions = SuggestionEngine.suggest(
        decisions: decisions, existingRules: rules,
        rejected: RuleStore(location: arguments.location).loadRejected(),
        config: try arguments.suggestionConfig())
    printSuggestions(suggestions)
    let disagreements = SuggestionEngine.disagreements(decisions: decisions, rules: rules)
    guard !disagreements.isEmpty else { return }
    print("\ndisagreements (\(disagreements.count)):")
    for d in disagreements {
        print("  \(d.summary) (you chose \(RuleAction.open(d.chosen)))")
    }
}

func printSuggestions(_ suggestions: [Suggestion]) {
    print("suggestions (\(suggestions.count)):")
    for (index, s) in suggestions.enumerated() {
        print("  \(index + 1). \(s.summary)")
    }
}

extension Arguments {
    func suggestionConfig() throws -> SuggestionConfig {
        var config = SuggestionConfig()
        if let value = options["min-support"] {
            guard let number = Double(value) else { throw CLIError.usage("bad --min-support") }
            config.minSupport = number
        }
        if let value = options["min-confidence"] {
            guard let number = Double(value) else { throw CLIError.usage("bad --min-confidence") }
            config.minConfidence = number
        }
        return config
    }
}
