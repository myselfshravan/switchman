import Foundation
import SwitchmanCore
import Testing

/// `count` identical picks of `url` into `target`.
func picks(_ count: Int, _ url: String, _ target: BrowserTarget, source: String? = nil)
    -> [Decision]
{
    Array(repeating: decision(url, target, source: source), count: count)
}

func suggest(_ decisions: [Decision], rules: [Rule] = [], rejected: Set<SuggestionShape> = [])
    -> [Suggestion]
{
    SuggestionEngine.suggest(decisions: decisions, existingRules: rules, rejected: rejected)
}

@Suite struct SuggestionEngineTests {
    @Test func cleanDomainSuggestsWildcard() throws {
        let s = suggest(
            picks(4, "https://notion.so/a", brave) + picks(2, "https://acme.notion.so/b", brave))
        #expect(s.count == 1)
        let only = try #require(s.first)
        #expect(only.pattern == .hostWildcard("*.notion.so"))
        #expect(only.action == .open(brave))
        #expect(only.sourceAppBundleID == nil)
        #expect(only.support == 6)
        #expect(only.confidence == 1)
        #expect(only.origin == .learned)
        #expect(only.examples == [key("https://notion.so/a"), key("https://acme.notion.so/b")])
    }

    @Test func belowMinSupportSuggestsNothing() {
        #expect(suggest(picks(4, "https://notion.so", brave)).isEmpty)
    }

    @Test func confidenceThresholdToleratesNoise() {
        let s = suggest(
            picks(9, "https://youtube.com/w", chrome) + picks(1, "https://youtube.com/w", brave))
        #expect(s.map(\.pattern) == [.hostWildcard("*.youtube.com")])
        #expect(s.first?.confidence == 0.9)
    }

    @Test func mixedDomainSplitsByHost() {
        let s = suggest(
            picks(6, "https://acme.atlassian.net/browse/X", brave)
                + picks(5, "https://home.atlassian.net/wiki", chrome))
        #expect(
            s.map(\.pattern) == [.host("acme.atlassian.net"), .host("home.atlassian.net")])
        #expect(s.map(\.action) == [.open(brave), .open(chrome)])
    }

    @Test func mixedHostSplitsByFirstPathSegment() {
        let s = suggest(
            picks(8, "https://github.com/acme/api", brave)
                + picks(6, "https://github.com/me/dotfiles", chrome)
                + picks(2, "https://github.com/rando/x", chrome))
        #expect(s.map(\.pattern) == [.urlPrefix("github.com/acme/"), .urlPrefix("github.com/me/")])
        #expect(s.map(\.action) == [.open(brave), .open(chrome)])
    }

    @Test func mixedHostSplitsByAccountHintBeforePath() {
        let s = suggest(
            picks(5, "https://docs.google.com/document/d/1?authuser=1", brave)
                + picks(3, "https://docs.google.com/spreadsheets/d/2?authuser=1", brave)
                + picks(6, "https://docs.google.com/document/d/3", chrome))
        #expect(
            s.map(\.pattern) == [
                .regex(#"^docs\.google\.com(/[^?]*)?\?authuser=1$"#),
                .regex(#"^docs\.google\.com(/[^?]*)?$"#),
            ])
        #expect(s.map(\.action) == [.open(brave), .open(chrome)])
        for suggestion in s {
            #expect(suggestion.examples.allSatisfy(suggestion.pattern.matches))
        }
    }

    @Test func splitsBySourceAppWhenEverySourceIsClean() {
        let s = suggest(
            picks(7, "https://figma.com/file/1", brave, source: slack)
                + picks(5, "https://figma.com/file/1", chrome, source: "com.apple.MobileSMS"))
        #expect(s.map(\.sourceAppBundleID) == [slack, "com.apple.MobileSMS"])
        #expect(s.allSatisfy { $0.pattern == .hostWildcard("*.figma.com") })
        #expect(s.map(\.action) == [.open(brave), .open(chrome)])
    }

    @Test func unknownSourceBecomesTheAnySourceFallback() {
        let s = suggest(
            picks(7, "https://figma.com/f", brave, source: slack)
                + picks(5, "https://figma.com/f", chrome))
        #expect(s.map(\.sourceAppBundleID) == [slack, nil])
    }

    @Test func irreducibleMixSuggestsAlwaysAsk() throws {
        let s = suggest(
            picks(5, "https://mail.google.com/mail/u/0/", chrome)
                + picks(5, "https://mail.google.com/mail/u/1/", brave))
        let only = try #require(s.first)
        #expect(s.count == 1)
        #expect(only.pattern == .hostWildcard("*.google.com"))
        #expect(only.action == .alwaysAsk)
        #expect(only.confidence == 0.5)
    }

    @Test func partialSplitKeepsCleanPartsAndAsksForTheRest() {
        let s = suggest(
            picks(10, "https://youtube.com/watch", chrome)
                + picks(3, "https://music.youtube.com/a", chrome)
                + picks(3, "https://music.youtube.com/a", brave))
        #expect(s.map(\.pattern) == [.host("youtube.com"), .host("music.youtube.com")])
        #expect(s.map(\.action) == [.open(chrome), .alwaysAsk])
    }

    @Test func decisionsAlreadyRoutedByRulesAreIgnored() {
        let rules = [Rule(pattern: .host("github.com"), action: .open(chrome))]
        #expect(suggest(picks(10, "https://github.com/x", brave), rules: rules).isEmpty)
    }

    @Test func alwaysAskRulesDoNotHideEvidenceButAreNotDuplicated() {
        let ask = [Rule(pattern: .hostWildcard("*.google.com"), action: .alwaysAsk)]
        let mixed =
            picks(5, "https://mail.google.com/mail/u/0/", chrome)
            + picks(5, "https://mail.google.com/mail/u/1/", brave)
        #expect(suggest(mixed, rules: ask).isEmpty)
        let clean = suggest(picks(6, "https://docs.google.com/d", brave), rules: ask)
        #expect(clean.map(\.pattern) == [.hostWildcard("*.google.com")])
        #expect(clean.map(\.action) == [.open(brave)])
    }

    @Test func rejectedSuggestionsAreNotSuggestedAgain() throws {
        let decisions = picks(6, "https://notion.so/a", brave)
        let first = try #require(suggest(decisions).first)
        #expect(suggest(decisions, rejected: [first.shape]).isEmpty)
    }

    @Test func sortedBySupportDescending() {
        let s = suggest(picks(5, "https://a.com", brave) + picks(9, "https://b.com", chrome))
        #expect(s.map(\.support) == [9, 5])
    }

    @Test func importedOnlyEvidenceIsMarkedImported() {
        let imported = (0..<3).map { _ in
            Decision(
                date: .now, key: key("https://notion.so"), chosen: brave, kind: .imported,
                weight: 2)
        }
        #expect(suggest(imported).first?.origin == .imported)
        #expect(suggest(imported + picks(1, "https://notion.so", brave)).first?.origin == .learned)
    }

    @Test func acceptingASuggestionMakesARuleThatRoutesItsExamples() throws {
        let s = try #require(suggest(picks(6, "https://github.com/acme/x", brave)).first)
        let rule = s.makeRule()
        #expect(rule.origin == .learned)
        #expect(rule.pattern == s.pattern)
        #expect(
            Router.route(key("https://github.com/acme/x"), sourceApp: nil, rules: [rule])
                == .open(brave, reason: .rule(index: 0, rule)))
    }
}
