import Foundation
import SwitchmanCore
import Testing

let brave = BrowserTarget(bundleID: "com.brave.Browser")
let chrome = BrowserTarget(bundleID: "com.google.Chrome", profileDirectory: "Profile 1")
let slack = "com.tinyspeck.slackmacgap"

func rule(_ pattern: Pattern, _ action: RuleAction, source: String? = nil, enabled: Bool = true)
    -> Rule
{
    Rule(pattern: pattern, sourceAppBundleID: source, action: action, enabled: enabled)
}

@Suite struct RouterTests {
    @Test func noRulesAsks() {
        #expect(
            Router.route(key("https://x.com"), sourceApp: nil, rules: []) == .ask(reason: .noRule))
    }

    @Test func firstMatchingRuleWins() {
        let rules = [
            rule(.urlPrefix("github.com/acme"), .open(brave)),
            rule(.host("github.com"), .open(chrome)),
        ]
        #expect(
            Router.route(key("https://github.com/acme/x"), sourceApp: nil, rules: rules)
                == .open(brave, reason: .rule(index: 0, rules[0])))
        #expect(
            Router.route(key("https://github.com/me"), sourceApp: nil, rules: rules)
                == .open(chrome, reason: .rule(index: 1, rules[1])))
    }

    @Test func disabledRulesAreSkipped() {
        let rules = [rule(.host("github.com"), .open(brave), enabled: false)]
        #expect(
            Router.route(key("https://github.com"), sourceApp: nil, rules: rules)
                == .ask(reason: .noRule))
    }

    @Test func sourceScopedRuleOnlyMatchesThatSource() {
        let rules = [
            rule(.host("github.com"), .open(brave), source: slack),
            rule(.host("github.com"), .open(chrome)),
        ]
        let k = key("https://github.com")
        #expect(
            Router.route(k, sourceApp: slack, rules: rules)
                == .open(brave, reason: .rule(index: 0, rules[0])))
        #expect(
            Router.route(k, sourceApp: "com.apple.Notes", rules: rules)
                == .open(chrome, reason: .rule(index: 1, rules[1])))
        #expect(
            Router.route(k, sourceApp: nil, rules: rules)
                == .open(chrome, reason: .rule(index: 1, rules[1])))
    }

    @Test func alwaysAskRuleAsksWithRuleAsReason() {
        let rules = [rule(.hostWildcard("*.google.com"), .alwaysAsk)]
        #expect(
            Router.route(key("https://docs.google.com"), sourceApp: nil, rules: rules)
                == .ask(reason: .rule(index: 0, rules[0])))
    }

    @Test func optionKeyForcesThePicker() {
        let rules = [rule(.host("github.com"), .open(brave))]
        #expect(
            Router.route(
                key("https://github.com"), sourceApp: nil, rules: rules, modifiers: .option)
                == .ask(reason: .forcedByModifier))
    }

    @Test func explanationNamesBrowserRuleAndSource() {
        let r = Rule(
            pattern: .urlPrefix("github.com/acme/"), sourceAppBundleID: slack, action: .open(brave))
        let names = ["com.brave.Browser": "Brave", slack: "Slack"]
        let name: (String) -> String = { names[$0] ?? $0 }
        #expect(
            RouteResult.open(brave, reason: .rule(index: 3, r)).explanation(appName: name)
                == "Brave — rule #4 github.com/acme/*, source: Slack")
        #expect(
            RouteResult.open(chrome, reason: .rule(index: 0, rule(.host("x.com"), .open(chrome))))
                .explanation() == "com.google.Chrome (Profile 1) — rule #1 x.com")
        #expect(RouteResult.ask(reason: .noRule).explanation() == "Ask — no rule matches")
        #expect(RouteResult.ask(reason: .forcedByModifier).explanation() == "Ask — Option key held")
        #expect(
            RouteResult.ask(reason: .rule(index: 1, rule(.host("google.com"), .alwaysAsk)))
                .explanation() == "Ask — rule #2 google.com is always-ask")
    }
}
