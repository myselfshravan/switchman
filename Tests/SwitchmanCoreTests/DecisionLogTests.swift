import Foundation
import SwitchmanCore
import Testing

func decision(
    _ url: String, _ chosen: BrowserTarget, kind: Decision.Kind = .picked, source: String? = nil,
    date: Date = Date(timeIntervalSince1970: 1_700_000_000)
) -> Decision {
    Decision(date: date, key: key(url), sourceAppBundleID: source, chosen: chosen, kind: kind)
}

@Suite struct DecisionLogTests {
    let dir: TemporaryDirectory
    let location: StoreLocation

    init() throws {
        dir = try TemporaryDirectory()
        location = StoreLocation(base: dir.url)
    }

    @Test func defaultWeightsByKind() {
        #expect(decision("https://a.com", brave, kind: .picked).weight == 1)
        #expect(decision("https://a.com", brave, kind: .autoRouted).weight == 1)
        #expect(decision("https://a.com", brave, kind: .corrected).weight == 3)
    }

    @Test func importedWeightIsLogScaledVisitCount() {
        #expect(Decision.importedWeight(visitCount: 0) == 0)
        #expect(Decision.importedWeight(visitCount: 1) == 1)
        #expect(Decision.importedWeight(visitCount: 7) == 3)
    }

    @Test func appendsOneJSONLinePerDecisionAndReadsBack() throws {
        var log = DecisionLog(location: location)
        let first = decision("https://github.com/acme/x?secret=1#frag", brave, source: slack)
        let second = decision("https://youtube.com/watch?v=1", chrome, kind: .corrected)
        try log.append(first)
        try log.append(second)

        let text = try String(contentsOf: location.decisions, encoding: .utf8)
        #expect(text.split(separator: "\n").count == 2)
        #expect(!text.contains("secret"))
        #expect(!text.contains("frag"))
        #expect(try log.readAll() == [first, second])
    }

    @Test func missingLogReadsEmpty() throws {
        #expect(try DecisionLog(location: location).readAll().isEmpty)
    }

    @Test func skipsCorruptLines() throws {
        var log = DecisionLog(location: location)
        let good = decision("https://a.com", brave)
        try log.append(good)
        let handle = try FileHandle(forWritingTo: location.decisions)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("{ truncated\n".utf8))
        try handle.close()
        try log.append(good)
        #expect(try log.readAll() == [good, good])
    }

    @Test func rollsOldestOffPastTheCap() throws {
        var log = DecisionLog(location: location, cap: 3)
        let decisions = (0..<5).map {
            decision("https://a.com/\($0)", brave, date: Date(timeIntervalSince1970: Double($0)))
        }
        for d in decisions { try log.append(d) }
        #expect(try log.readAll() == Array(decisions.suffix(3)))

        var reopened = DecisionLog(location: location, cap: 3)
        try reopened.append(decisions[0])
        #expect(try reopened.readAll() == [decisions[3], decisions[4], decisions[0]])
    }
}
