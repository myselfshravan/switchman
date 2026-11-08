import Foundation
import Testing

let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent().appendingPathComponent("Fixtures")
let home = fixtures.appendingPathComponent("home").path

@Suite struct ExplainCommandTests {
    @Test func explainsSourceScopedRule() throws {
        let r = try runCLI([
            "explain", "https://github.com/acme/repo?x=1", "--source", "com.tinyspeck.slackmacgap",
            "--home", home,
        ])
        #expect(r.status == 0)
        #expect(
            r.stdout == """
                key:    github.com/acme/repo
                result: com.brave.Browser — rule #1 github.com/acme/*, source: com.tinyspeck.slackmacgap

                """)
    }

    @Test func sameLinkFromAnotherSourceFallsThrough() throws {
        let r = try runCLI(["explain", "https://github.com/acme/repo", "--home", home])
        #expect(r.stdout.contains("result: Ask — no rule matches"))
    }

    @Test func explainsAlwaysAskAndProfiles() throws {
        let ask = try runCLI(["explain", "https://docs.google.com/d/1?authuser=1", "--home", home])
        #expect(ask.stdout.contains("key:    docs.google.com/d/1?authuser=1"))
        #expect(ask.stdout.contains("result: Ask — rule #2 *.google.com is always-ask"))
        let yt = try runCLI(["explain", "https://www.youtube.com/watch?v=1", "--home", home])
        #expect(yt.stdout.contains("result: com.google.Chrome (Profile 1) — rule #3 youtube.com"))
    }

    @Test func missingRulesFileMeansNoRules() throws {
        let empty = fixtures.appendingPathComponent("does-not-exist").path
        let r = try runCLI(["explain", "https://example.com", "--home", empty])
        #expect(r.status == 0)
        #expect(r.stdout.contains("result: Ask — no rule matches"))
    }

    @Test func rejectsNonWebURL() throws {
        let r = try runCLI(["explain", "mailto:a@b.com", "--home", home])
        #expect(r.status == 65)
        #expect(r.stderr.contains("not an http(s) URL"))
    }

    @Test func missingURLIsUsageError() throws {
        let r = try runCLI(["explain", "--home", home])
        #expect(r.status == 64)
    }
}

@Suite struct RulesCommandTests {
    @Test func listsRulesInOrder() throws {
        let r = try runCLI(["rules", "list", "--home", home])
        #expect(r.status == 0)
        #expect(
            r.stdout == """
                #1  github.com/acme/*  → com.brave.Browser  from com.tinyspeck.slackmacgap
                #2  *.google.com  → ask
                #3  youtube.com  → com.google.Chrome (Profile 1)
                #4  news.ycombinator.com  → com.brave.Browser  (disabled)

                """)
    }

    @Test func validatePassesForGoodFile() throws {
        let r = try runCLI(["rules", "validate", "--home", home])
        #expect(r.status == 0)
        #expect(r.stdout == "4 rules OK\n")
    }

    @Test func validateReportsEachBadRule() throws {
        let bad = fixtures.appendingPathComponent("bad-home").path
        let r = try runCLI(["rules", "validate", "--home", bad])
        #expect(r.status == 65)
        #expect(r.stderr.contains("rule #1: invalid regex"))
        #expect(r.stderr.contains("rule #2: host is empty"))
    }

    @Test func corruptFileIsReported() throws {
        let r = try runCLI([
            "rules", "list", "--home", fixtures.appendingPathComponent("corrupt-home").path,
        ])
        #expect(r.status == 65)
        #expect(r.stderr.contains("rules.json"))
    }
}
