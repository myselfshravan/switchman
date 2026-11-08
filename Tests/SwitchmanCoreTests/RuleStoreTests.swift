import Foundation
import SwitchmanCore
import Testing

@Suite struct RuleStoreTests {
    let dir: TemporaryDirectory
    let location: StoreLocation

    init() throws {
        dir = try TemporaryDirectory()
        location = StoreLocation(base: dir.url.appendingPathComponent("nested/Switchman"))
    }

    @Test func missingFileLoadsNoRulesAndNoError() {
        var store = RuleStore(location: location)
        store.reload()
        #expect(store.rules.isEmpty)
        #expect(store.lastError == nil)
    }

    @Test func saveCreatesDirectoryAndRoundTrips() throws {
        let rules = [
            Rule(pattern: .host("a.com"), action: .open(brave)),
            Rule(pattern: .hostWildcard("*.b.com"), action: .alwaysAsk),
        ]
        var store = RuleStore(location: location)
        try store.save(rules)
        #expect(store.rules == rules)

        var reopened = RuleStore(location: location)
        reopened.reload()
        #expect(reopened.rules == rules)
    }

    @Test func corruptFileKeepsLastGoodRulesAndSurfacesError() throws {
        let good = [Rule(pattern: .host("a.com"), action: .open(brave))]
        var store = RuleStore(location: location)
        try store.save(good)
        try Data("{ not json".utf8).write(to: location.rules)

        store.reload()
        #expect(store.rules == good)
        #expect(store.lastError?.contains("rules.json") == true)

        try store.save(good)
        store.reload()
        #expect(store.lastError == nil)
    }

    @Test func addPutsNewRuleFirstSoItWins() throws {
        var store = RuleStore(location: location)
        try store.save([Rule(pattern: .host("a.com"), action: .open(chrome))])
        let added = Rule(pattern: .urlPrefix("a.com/work"), action: .open(brave))
        try store.add(added)
        #expect(store.rules.first == added)
        #expect(store.rules.count == 2)
    }
}
