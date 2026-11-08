import Foundation
import SwitchmanCore
import Testing

@Suite struct DisagreementTests {
    let rules = [
        Rule(pattern: .hostWildcard("*.google.com"), action: .alwaysAsk),
        Rule(pattern: .hostWildcard("*.atlassian.net"), action: .open(chrome)),
    ]

    @Test func correctionsAgainstARuleAreCountedPerRule() throws {
        let decisions =
            picks(3, "https://acme.atlassian.net/x", chrome)
            + Array(
                repeating: decision("https://acme.atlassian.net/x", brave, kind: .corrected),
                count: 4)
            + [decision("https://docs.google.com", brave, kind: .corrected)]
        let found = SuggestionEngine.disagreements(decisions: decisions, rules: rules)
        let only = try #require(found.first)
        #expect(found.count == 1)
        #expect(only.ruleIndex == 1)
        #expect(only.rule == rules[1])
        #expect(only.count == 4)
        #expect(only.chosen == brave)
        #expect(only.examples == [key("https://acme.atlassian.net/x")])
        #expect(only.summary == "rule #2 *.atlassian.net disagrees with you 4 times")
    }

    @Test func correctionsThatAgreeOrMatchNoRuleAreNotDisagreements() {
        let decisions = [
            decision("https://acme.atlassian.net", chrome, kind: .corrected),
            decision("https://unruled.com", brave, kind: .corrected),
        ]
        #expect(SuggestionEngine.disagreements(decisions: decisions, rules: rules).isEmpty)
    }
}
