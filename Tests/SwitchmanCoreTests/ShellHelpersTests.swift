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
        decisions: picks(
            1, "https://gitlab.com/acme/app/-/merge_requests/1834", brave, source: slack)
            + picks(1, "https://gitlab.com/acme/app/-/merge_requests/1836", brave, source: slack)
            + picks(2, "https://figma.com/f", chrome),
        existingRules: [], config: PickerHint.config)

    @Test func twoPicksOfDifferentLinksOnOneDomainAreEnough() throws {
        let hint = try #require(
            PickerHint.find(for: key("https://gitlab.com/other"), sourceApp: slack, in: suggestions)
        )
        #expect(hint.target == brave)
        #expect(hint.rule.pattern == .hostWildcard("*.gitlab.com"))
        #expect(hint.label == "Always use this for *.gitlab.com (picked 2×)")
    }

    @Test func onePickOrMixedPicksGiveNoHint() {
        let one = SuggestionEngine.suggest(
            decisions: picks(1, "https://gitlab.com/a", brave), existingRules: [],
            config: PickerHint.config)
        #expect(PickerHint.find(for: key("https://gitlab.com/a"), sourceApp: nil, in: one) == nil)
        let mixed = SuggestionEngine.suggest(
            decisions: picks(1, "https://gitlab.com/a", brave)
                + picks(1, "https://gitlab.com/a", chrome),
            existingRules: [], config: PickerHint.config)
        #expect(PickerHint.find(for: key("https://gitlab.com/a"), sourceApp: nil, in: mixed) == nil)
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

    @Test func returnAcceptsTheSuggestedChoiceWithRemember() {
        var state = PickerState(count: 3, suggested: 2)
        #expect(state.highlighted == 2)
        #expect(state.remember)
        #expect(state.handle(.confirm) == .pick(index: 2, remember: true))
    }

    @Test func pickingAnotherBrowserDoesNotInheritThePreTick() {
        var state = PickerState(count: 3, suggested: 2)
        #expect(state.handle(.number(1)) == .pick(index: 0, remember: false))
    }

    @Test func explicitToggleIsRespectedForAnyChoice() {
        var untick = PickerState(count: 3, suggested: 2)
        _ = untick.handle(.toggleRemember)
        #expect(untick.handle(.confirm) == .pick(index: 2, remember: false))

        var retick = PickerState(count: 3, suggested: 2)
        _ = retick.handle(.toggleRemember)
        _ = retick.handle(.toggleRemember)
        #expect(retick.handle(.number(1)) == .pick(index: 0, remember: true))
    }
}
