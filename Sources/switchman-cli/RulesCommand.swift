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
