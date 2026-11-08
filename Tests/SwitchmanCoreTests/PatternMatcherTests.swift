import SwitchmanCore
import Testing

func key(_ string: String) -> URLKey { URLKey(string, suffixes: .bundled)! }

@Suite struct PatternMatcherTests {
    @Test func hostMatchesExactHostOnly() {
        let p = Pattern.host("github.com")
        #expect(p.matches(key("https://github.com/acme")))
        #expect(p.matches(key("https://www.github.com/")))
        #expect(!p.matches(key("https://api.github.com/")))
        #expect(!p.matches(key("https://notgithub.com/")))
    }

    @Test func hostIsCaseInsensitiveAndIgnoresPortUnlessGiven() {
        #expect(Pattern.host("GitHub.com").matches(key("https://github.com")))
        #expect(Pattern.host("localhost").matches(key("http://localhost:3000/")))
        #expect(Pattern.host("localhost:3000").matches(key("http://localhost:3000/")))
        #expect(!Pattern.host("localhost:3000").matches(key("http://localhost:8080/")))
    }

    @Test func hostWildcardMatchesSubdomainsAndApex() {
        let p = Pattern.hostWildcard("*.atlassian.net")
        #expect(p.matches(key("https://acme.atlassian.net/browse/X-1")))
        #expect(p.matches(key("https://a.b.atlassian.net/")))
        #expect(p.matches(key("https://atlassian.net/")))
        #expect(!p.matches(key("https://evilatlassian.net/")))
    }

    @Test func urlPrefixMatchesWholePathSegments() {
        let p = Pattern.urlPrefix("github.com/acme/")
        #expect(p.matches(key("https://github.com/acme")))
        #expect(p.matches(key("https://github.com/acme/repo/pulls")))
        #expect(!p.matches(key("https://github.com/acmecorp/repo")))
        #expect(!p.matches(key("https://github.com/")))
        #expect(!p.matches(key("https://gist.github.com/acme")))
    }

    @Test func urlPrefixHostIsCaseInsensitivePathIsNot() {
        #expect(
            Pattern.urlPrefix("https://WWW.GitHub.com/acme").matches(
                key("https://github.com/acme/x")))
        #expect(!Pattern.urlPrefix("github.com/Acme").matches(key("https://github.com/acme/x")))
    }

    @Test func regexSearchesTheKeyString() {
        let p = Pattern.regex(#"^docs\.google\.com/.*\?authuser=1"#)
        #expect(p.matches(key("https://docs.google.com/document/d/1?authuser=1")))
        #expect(!p.matches(key("https://docs.google.com/document/d/1?authuser=0")))
        #expect(Pattern.regex("acme").matches(key("https://gitlab.com/acme/x")))
    }

    @Test func invalidRegexNeverMatchesAndFailsValidation() {
        let p = Pattern.regex("([unclosed")
        #expect(!p.matches(key("https://example.com")))
        #expect(p.validationError != nil)
        #expect(Pattern.regex("ok.*").validationError == nil)
    }

    @Test func emptyPatternsFailValidation() {
        #expect(Pattern.host("").validationError != nil)
        #expect(Pattern.hostWildcard("*.").validationError != nil)
        #expect(Pattern.urlPrefix("/").validationError != nil)
        #expect(Pattern.host("github.com").validationError == nil)
    }

    @Test func descriptionIsHumanReadable() {
        #expect(Pattern.host("github.com").description == "github.com")
        #expect(Pattern.hostWildcard("*.atlassian.net").description == "*.atlassian.net")
        #expect(Pattern.urlPrefix("github.com/acme/").description == "github.com/acme/*")
        #expect(Pattern.regex("a.*b").description == "/a.*b/")
    }
}
