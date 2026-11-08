import Foundation
import SwitchmanCore
import Testing

@Suite struct RulesFileTests {
    let id = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!

    @Test func encodesPrettyWithStableKeyOrder() throws {
        let rules = [Rule(id: id, pattern: .host("a.com"), action: .open(brave))]
        let text = String(decoding: try RulesFile.encode(rules), as: UTF8.self)
        #expect(
            text == """
                {
                  "rules" : [
                    {
                      "enabled" : true,
                      "id" : "00000000-0000-4000-8000-000000000001",
                      "open" : {
                        "bundleID" : "com.brave.Browser"
                      },
                      "origin" : "manual",
                      "pattern" : {
                        "host" : "a.com"
                      }
                    }
                  ],
                  "version" : 1
                }

                """)
    }

    @Test func roundTripsOrderedRules() throws {
        let rules = [
            Rule(pattern: .host("a.com"), action: .open(brave)),
            Rule(pattern: .hostWildcard("*.b.com"), action: .alwaysAsk, origin: .learned),
        ]
        #expect(try RulesFile.decode(RulesFile.encode(rules)) == rules)
    }

    @Test func rejectsNewerVersion() {
        #expect(throws: RulesFile.Error.unsupportedVersion(2)) {
            try RulesFile.decode(Data(#"{"version": 2, "rules": []}"#.utf8))
        }
    }

    @Test func validationListsEveryProblemWithRuleNumbers() {
        let rules = [
            Rule(pattern: .host("ok.com"), action: .alwaysAsk),
            Rule(pattern: .regex("("), action: .alwaysAsk),
            Rule(pattern: .urlPrefix(""), action: .alwaysAsk),
        ]
        let problems = RulesFile.problems(in: rules)
        #expect(problems.count == 2)
        #expect(problems[0].hasPrefix("rule #2: invalid regex"))
        #expect(problems[1] == "rule #3: urlPrefix has no host")
    }

    @Test func storeLocationDefaultsToApplicationSupport() {
        let location = StoreLocation.default
        #expect(location.base.path.hasSuffix("Library/Application Support/Switchman"))
        #expect(location.rules.lastPathComponent == "rules.json")
        #expect(location.decisions.lastPathComponent == "decisions.jsonl")
    }
}
