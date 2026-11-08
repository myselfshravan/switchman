import Foundation
import Testing

@Suite struct SuggestCommandTests {
    let golden = fixtures.appendingPathComponent("golden").path

    @Test func printsSuggestionsAndDisagreementsFromTheLog() throws {
        let r = try runCLI(["suggest", "--home", golden])
        #expect(r.status == 0)
        let lines = r.stdout.split(separator: "\n").map(String.init)
        #expect(lines.first == "suggestions (10):")
        #expect(
            lines[1]
                == "  1. github.com/acme/*  → com.brave.Browser  (support 40, 100%)  e.g. github.com/acme/api/pull/12"
        )
        #expect(
            lines.contains(
                "  5. mail.google.com  → ask  (support 22, 55%)  e.g. mail.google.com/mail/u/1"))
        #expect(
            lines.contains(
                "  8. *.figma.com  → com.brave.Browser  from com.tinyspeck.slackmacgap  (support 12, 100%)  e.g. figma.com/file/WORK/design"
            ))
        #expect(
            lines.suffix(2) == [
                "disagreements (1):",
                "  rule #1 *.atlassian.net disagrees with you 4 times (you chose com.brave.Browser)",
            ])
    }

    @Test func minSupportFiltersSmallGroups() throws {
        let r = try runCLI(["suggest", "--home", golden, "--min-support", "30"])
        #expect(r.stdout.hasPrefix("suggestions (3):"))
    }

    @Test func badNumberIsUsageError() throws {
        let r = try runCLI(["suggest", "--home", golden, "--min-support", "lots"])
        #expect(r.status == 64)
    }
}
