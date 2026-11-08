import SwitchmanCore
import Testing

@Suite struct SummaryTests {
    @Test func ruleSummaryShowsPatternActionSourceAndState() {
        let r = Rule(
            pattern: .urlPrefix("github.com/acme/"), sourceAppBundleID: slack, action: .open(chrome)
        )
        #expect(r.summary == "github.com/acme/*  → com.google.Chrome (Profile 1)  from \(slack)")
        let off = Rule(pattern: .host("a.com"), action: .alwaysAsk, enabled: false)
        #expect(off.summary == "a.com  → ask  (disabled)")
    }

    @Test func suggestionSummaryAddsSupportConfidenceAndExample() {
        let s = Suggestion(
            pattern: .host("a.com"), sourceAppBundleID: nil, action: .open(brave), support: 12.5,
            confidence: 0.966, examples: [key("https://a.com/x")], origin: .imported)
        #expect(
            s.summary == "a.com  → com.brave.Browser  (support 12.5, 97%, imported)  e.g. a.com/x")
        let whole = Suggestion(
            pattern: .host("a.com"), sourceAppBundleID: nil, action: .alwaysAsk, support: 40,
            confidence: 0.5, examples: [], origin: .learned)
        #expect(whole.summary == "a.com  → ask  (support 40, 50%)")
    }
}
