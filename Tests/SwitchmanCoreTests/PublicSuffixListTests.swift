import SwitchmanCore
import Testing

@Suite struct PublicSuffixListTests {
    let list = PublicSuffixList(
        text: """
            // comment lines and blanks are ignored

            com
            in
            co.in
            *.ck
            !www.ck
            github.io
            """)

    @Test(arguments: [
        ("github.com", "github.com"),
        ("api.github.com", "github.com"),
        ("foo.bar.co.in", "bar.co.in"),
        ("bar.co.in", "bar.co.in"),
        ("a.b.foo.ck", "b.foo.ck"),
        ("www.ck", "www.ck"),
        ("x.www.ck", "www.ck"),
        ("acme.github.io", "acme.github.io"),
        ("deep.acme.github.io", "acme.github.io"),
        ("example.unknowntld", "example.unknowntld"),
    ])
    func registrableDomain(host: String, expected: String) {
        #expect(list.registrableDomain(for: host) == expected)
    }

    @Test(arguments: ["co.in", "com", "foo.ck", "localhost", "127.0.0.1", "::1", "10.0.0.12"])
    func suffixesIPsAndSingleLabelsMapToThemselves(host: String) {
        #expect(list.registrableDomain(for: host) == host)
    }

    @Test func bundledListLoadsRealSuffixes() {
        let bundled = PublicSuffixList.bundled
        #expect(bundled.registrableDomain(for: "foo.bar.co.uk") == "bar.co.uk")
        #expect(bundled.registrableDomain(for: "acme.atlassian.net") == "atlassian.net")
        #expect(bundled.registrableDomain(for: "me.github.io") == "me.github.io")
    }
}
