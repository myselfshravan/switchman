import SwitchmanCore
import Testing

@Suite struct TrackingParametersTests {
    @Test func stripsKnownTrackersAndKeepsEverythingElse() {
        #expect(
            TrackingParameters.strip(
                "https://shop.com/p?id=7&utm_source=x&utm_medium=y&fbclid=abc&gclid=1#reviews")
                == "https://shop.com/p?id=7#reviews")
    }

    @Test func dropsTheQuestionMarkWhenNothingIsLeft() {
        #expect(TrackingParameters.strip("https://a.com/?utm_campaign=z") == "https://a.com/")
    }

    @Test func leavesCleanAndUnparseableURLsAlone() {
        #expect(
            TrackingParameters.strip("https://a.com/x?q=utm_source")
                == "https://a.com/x?q=utm_source")
        #expect(TrackingParameters.strip("not a url") == "not a url")
    }
}

@Suite struct PickerStateTests {
    @Test func numberKeysPickDirectly() {
        var state = PickerState(count: 3)
        #expect(state.handle(.number(2)) == .pick(index: 1, remember: false))
        #expect(state.handle(.number(4)) == nil)
        #expect(state.handle(.number(0)) == nil)
    }

    @Test func arrowsMoveTheHighlightAndWrap() {
        var state = PickerState(count: 3)
        #expect(state.highlighted == 0)
        _ = state.handle(.up)
        #expect(state.highlighted == 2)
        _ = state.handle(.down)
        _ = state.handle(.down)
        #expect(state.highlighted == 1)
        #expect(state.handle(.confirm) == .pick(index: 1, remember: false))
    }

    @Test func rememberToggleCarriesIntoThePick() {
        var state = PickerState(count: 2)
        #expect(state.handle(.toggleRemember) == nil)
        #expect(state.remember)
        #expect(state.handle(.number(1)) == .pick(index: 0, remember: true))
    }

    @Test func escapeCancels() {
        var state = PickerState(count: 2)
        #expect(state.handle(.cancel) == .cancel)
    }

    @Test func emptyPickerCanOnlyCancel() {
        var state = PickerState(count: 0)
        #expect(state.handle(.confirm) == nil)
        #expect(state.handle(.down) == nil)
        #expect(state.highlighted == 0)
    }

    @Test func rememberRuleCoversTheWholeRegistrableDomain() {
        let rule = Rule.remembering(key("https://acme.atlassian.net/x"), opensIn: brave)
        #expect(rule.pattern == .hostWildcard("*.atlassian.net"))
        #expect(rule.action == .open(brave))
        #expect(rule.origin == .manual)
        #expect(rule.sourceAppBundleID == nil)
    }
}

@Suite struct PickerHintTests {
    let suggestions = SuggestionEngine.suggest(
        decisions: picks(3, "https://gitlab.com/acme/x", brave, source: slack)
            + picks(3, "https://figma.com/f", chrome),
        existingRules: [], config: PickerHint.config)

    @Test func learnsAfterThreeConsistentPicks() throws {
        let hint = try #require(
            PickerHint.find(for: key("https://gitlab.com/other"), sourceApp: slack, in: suggestions)
        )
        #expect(hint.target == brave)
        #expect(hint.rule.pattern == .hostWildcard("*.gitlab.com"))
        #expect(hint.label == "Always use this for *.gitlab.com (picked 3×)")
    }

    @Test func onlyMatchingKeysAndOpenSuggestionsGiveHints() {
        #expect(
            PickerHint.find(for: key("https://example.com"), sourceApp: nil, in: suggestions) == nil
        )
        let ask = [
            Suggestion(
                pattern: .host("a.com"), sourceAppBundleID: nil, action: .alwaysAsk, support: 9,
                confidence: 0.5, examples: [], origin: .learned)
        ]
        #expect(PickerHint.find(for: key("https://a.com"), sourceApp: nil, in: ask) == nil)
    }

    @Test func pickerStartsOnTheHintedChoiceWithRememberTicked() {
        var state = PickerState(count: 3, highlighted: 2, remember: true)
        #expect(state.handle(.confirm) == .pick(index: 2, remember: true))
    }
}
