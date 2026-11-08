import Foundation
import SwitchmanCore
import Testing

/// Realistic decision log → committed expected suggestions. To change the expectation on
/// purpose, run `SWITCHMAN_RECORD_GOLDEN=1 swift test` and review the diff.
@Suite struct GoldenSuggestionsTests {
    let golden = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().appendingPathComponent("Fixtures/golden")

    @Test func realisticLogProducesExpectedSuggestions() throws {
        let location = StoreLocation(base: golden)
        let decisions = try DecisionLog(location: location).readAll()
        #expect(decisions.count == 233)
        var store = RuleStore(location: location)
        store.reload()
        #expect(store.lastError == nil)

        let suggestions = SuggestionEngine.suggest(decisions: decisions, existingRules: store.rules)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let actual = try encoder.encode(suggestions) + Data("\n".utf8)
        let expectedURL = golden.appendingPathComponent("expected-suggestions.json")
        if ProcessInfo.processInfo.environment["SWITCHMAN_RECORD_GOLDEN"] == "1" {
            try actual.write(to: expectedURL)
        }
        #expect(
            String(decoding: actual, as: UTF8.self)
                == (try String(contentsOf: expectedURL, encoding: .utf8)))

        let disagreements = SuggestionEngine.disagreements(decisions: decisions, rules: store.rules)
        #expect(
            disagreements.map(\.summary) == ["rule #1 *.atlassian.net disagrees with you 4 times"])
    }
}
