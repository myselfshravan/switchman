import Foundation
import SwitchmanCore
import Testing

@Suite struct URLKeyTests {
    func key(_ string: String) -> URLKey? { URLKey(string, suffixes: .bundled) }

    @Test func normalisesHostAndDropsQueryAndFragment() throws {
        let k = try #require(key("HTTPS://WWW.GitHub.com/Acme/Repo/?tab=readme#top"))
        #expect(k.scheme == "https")
        #expect(k.host == "github.com")
        #expect(k.port == nil)
        #expect(k.registrableDomain == "github.com")
        #expect(k.pathSegments == ["Acme", "Repo"])
        #expect(k.hints.isEmpty)
        #expect(k.description == "github.com/Acme/Repo")
    }

    @Test func dropsDefaultPortsKeepsOthers() {
        #expect(key("http://example.com:80/")?.port == nil)
        #expect(key("https://example.com:443/")?.port == nil)
        #expect(key("http://localhost:3000/app")?.port == 3000)
        #expect(key("http://localhost:3000/app")?.description == "localhost:3000/app")
    }

    @Test func keepsAllowListedHintsSorted() {
        let k = key("https://docs.google.com/document/d/1?usp=sharing&u=0&authuser=1")
        #expect(k?.hints == ["authuser": "1", "u": "0"])
        #expect(k?.description == "docs.google.com/document/d/1?authuser=1&u=0")
    }

    @Test func registrableDomainUsesSuffixList() {
        #expect(key("https://foo.bar.co.in/x")?.registrableDomain == "bar.co.in")
        #expect(key("http://127.0.0.1:8080/")?.registrableDomain == "127.0.0.1")
        #expect(key("http://localhost/")?.registrableDomain == "localhost")
    }

    @Test(arguments: [
        "mailto:a@b.com", "ftp://example.com", "file:///etc/hosts", "not a url", "https://",
    ])
    func rejectsNonWebURLs(string: String) {
        #expect(key(string) == nil)
    }

    @Test func roundTripsThroughJSON() throws {
        let k = try #require(key("https://mail.google.com/mail/u/1/?authuser=1"))
        let data = try JSONEncoder().encode(k)
        #expect(try JSONDecoder().decode(URLKey.self, from: data) == k)
    }
}
