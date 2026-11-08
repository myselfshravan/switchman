/// Turns decisions into rule suggestions by hierarchical splitting: a domain that is "clean"
/// (one browser has ≥ minConfidence of the weight) becomes one rule; a mixed one is split by
/// host, account hint, path prefix, then source app; whatever stays mixed becomes `alwaysAsk`.
public enum SuggestionEngine {
    public static func suggest(
        decisions: [Decision], existingRules: [Rule], rejected: Set<SuggestionShape> = [],
        config: SuggestionConfig = .init()
    ) -> [Suggestion] {
        let uncovered = decisions.filter {
            if case .open = Router.route(
                $0.key, sourceApp: $0.sourceAppBundleID, rules: existingRules)
            {
                return false
            }
            return true
        }
        var domains: [String] = []
        let byDomain = Dictionary(grouping: uncovered, by: \.key.registrableDomain)
        for d in uncovered where !domains.contains(d.key.registrableDomain) {
            domains.append(d.key.registrableDomain)
        }
        let levels = Level.all(config)
        return
            domains
            .flatMap { analyse(byDomain[$0]!, Scope(domain: $0), levels[...], config) }
            .filter { !rejected.contains($0.shape) && !isRedundant($0, existingRules) }
            .stableSorted(descendingBy: \.support)
    }

    /// Corrections that contradict the rule which routed the link, grouped per rule.
    public static func disagreements(decisions: [Decision], rules: [Rule]) -> [Disagreement] {
        var found: [Int: [Decision]] = [:]
        for d in decisions where d.kind == .corrected {
            let result = Router.route(d.key, sourceApp: d.sourceAppBundleID, rules: rules)
            if case .open(let target, .rule(let index, _)) = result, target != d.chosen {
                found[index, default: []].append(d)
            }
        }
        return found.map { index, group in
            Disagreement(
                ruleIndex: index, rule: rules[index], count: group.count,
                chosen: Tally(group).winner, examples: examples(group))
        }
        .sorted { $0.count != $1.count ? $0.count > $1.count : $0.ruleIndex < $1.ruleIndex }
    }

    private static func analyse(
        _ group: [Decision], _ scope: Scope, _ levels: ArraySlice<Level>, _ config: SuggestionConfig
    ) -> [Suggestion] {
        let tally = Tally(group)
        guard tally.total >= config.minSupport else { return [] }
        if tally.share >= config.minConfidence {
            return [suggestion(scope, .open(tally.winner), group, tally)]
        }
        for (offset, level) in levels.enumerated() {
            let parts = level.split(group, in: scope)
            guard parts.count > 1 else { continue }
            let rest = levels.dropFirst(offset + 1)
            let children =
                level == .source
                ? sourceSplit(parts, config)
                : parts.flatMap { analyse($0.1, $0.0, rest, config) }
            if children.contains(where: { $0.action != .alwaysAsk }) { return children }
        }
        return [suggestion(scope, .alwaysAsk, group, tally)]
    }

    /// Source-scoped rules only make sense if every significant source app is clean.
    private static func sourceSplit(_ parts: [(Scope, [Decision])], _ config: SuggestionConfig)
        -> [Suggestion]
    {
        let results = parts.flatMap { analyse($0.1, $0.0, [], config) }
        return results.allSatisfy { $0.action != .alwaysAsk } ? results : []
    }

    private static func suggestion(
        _ scope: Scope, _ action: RuleAction, _ group: [Decision], _ tally: Tally
    ) -> Suggestion {
        Suggestion(
            pattern: scope.pattern, sourceAppBundleID: scope.source ?? nil, action: action,
            support: tally.total, confidence: tally.share, examples: examples(group),
            origin: group.allSatisfy { $0.kind == .imported } ? .imported : .learned)
    }

    /// Up to three distinct keys, heaviest first, ties in first-seen order.
    private static func examples(_ group: [Decision]) -> [URLKey] {
        var order: [URLKey] = []
        var weights: [URLKey: Double] = [:]
        for d in group {
            if weights[d.key] == nil { order.append(d.key) }
            weights[d.key, default: 0] += d.weight
        }
        return Array(order.stableSorted(descendingBy: { weights[$0]! }).prefix(3))
    }

    /// An existing rule already says the same thing: same shape, or already routes every
    /// example to this action.
    private static func isRedundant(_ s: Suggestion, _ rules: [Rule]) -> Bool {
        if rules.contains(where: {
            $0.enabled && $0.pattern == s.pattern && $0.sourceAppBundleID == s.sourceAppBundleID
                && $0.action == s.action
        }) {
            return true
        }
        return s.examples.allSatisfy { key in
            switch (Router.route(key, sourceApp: s.sourceAppBundleID, rules: rules), s.action) {
            case (.open(let target, _), .open(let wanted)): target == wanted
            case (.ask(.rule), .alwaysAsk): true
            default: false
            }
        }
    }
}

extension Array {
    /// Highest value first; ties keep their original order, so output is deterministic.
    fileprivate func stableSorted(descendingBy value: (Element) -> Double) -> [Element] {
        enumerated()
            .sorted {
                let (a, b) = (value($0.element), value($1.element))
                return a != b ? a > b : $0.offset < $1.offset
            }
            .map(\.element)
    }
}

/// Weighted votes per browser.
private struct Tally {
    var total: Double = 0
    var winner: BrowserTarget
    var share: Double

    init(_ group: [Decision]) {
        var weights: [BrowserTarget: Double] = [:]
        for d in group { weights[d.chosen, default: 0] += d.weight }
        total = weights.values.reduce(0, +)
        let best = weights.max {
            $0.value != $1.value ? $0.value < $1.value : $0.key.bundleID > $1.key.bundleID
        }!
        winner = best.key
        share = total > 0 ? best.value / total : 0
    }
}
