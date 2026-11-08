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
