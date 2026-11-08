import Foundation
import SwitchmanCore
import Testing

@Suite struct RuleCodingTests {
    func decode(_ json: String) throws -> Rule {
        try JSONDecoder().decode(Rule.self, from: Data(json.utf8))
    }

    @Test func decodesHandWrittenRuleWithDefaults() throws {
        let r = try decode(
            #"{"pattern": {"urlPrefix": "github.com/acme/"}, "open": {"bundleID": "com.brave.Browser"}}"#
        )
        #expect(r.pattern == .urlPrefix("github.com/acme/"))
        #expect(r.action == .open(brave))
        #expect(r.sourceAppBundleID == nil)
        #expect(r.enabled)
        #expect(r.origin == .manual)
        #expect(r.note == nil)
    }

    @Test func decodesEveryField() throws {
        let r = try decode(
            #"""
            {"id": "7C1A2C0E-0000-4000-8000-000000000001", "pattern": {"hostWildcard": "*.google.com"},
             "sourceApp": "com.tinyspeck.slackmacgap", "alwaysAsk": true, "enabled": false,
             "origin": "learned", "note": "two accounts"}
            """#)
        #expect(r.id == UUID(uuidString: "7C1A2C0E-0000-4000-8000-000000000001"))
        #expect(r.pattern == .hostWildcard("*.google.com"))
        #expect(r.sourceAppBundleID == slack)
        #expect(r.action == .alwaysAsk)
        #expect(!r.enabled)
        #expect(r.origin == .learned)
        #expect(r.note == "two accounts")
    }

    @Test func rejectsRuleWithoutExactlyOneAction() {
        #expect(throws: DecodingError.self) { try decode(#"{"pattern": {"host": "a.com"}}"#) }
        #expect(throws: DecodingError.self) {
            try decode(
                #"{"pattern": {"host": "a.com"}, "alwaysAsk": true, "open": {"bundleID": "x"}}"#)
        }
    }

    @Test func rejectsUnknownPatternKind() {
        #expect(throws: DecodingError.self) {
            try decode(#"{"pattern": {"glob": "a.com"}, "alwaysAsk": true}"#)
        }
    }

    @Test(arguments: [
        Pattern.host("a.com"), .hostWildcard("*.a.com"), .urlPrefix("a.com/x/"), .regex("^a"),
    ])
    func roundTripsEveryPatternAndAction(pattern: Pattern) throws {
        for action in [RuleAction.open(chrome), .alwaysAsk] {
            let r = Rule(
                pattern: pattern, sourceAppBundleID: slack, action: action, origin: .imported,
                note: "n")
            let data = try JSONEncoder().encode(r)
            #expect(try JSONDecoder().decode(Rule.self, from: data) == r)
        }
    }
}
