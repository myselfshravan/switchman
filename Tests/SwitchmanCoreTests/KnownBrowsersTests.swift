import SwitchmanCore
import Testing

@Suite struct KnownBrowsersTests {
    @Test func otherLinkRoutersAreExcluded() {
        #expect(KnownBrowsers.isLinkRouter("com.browserosaurus"))
        #expect(KnownBrowsers.isLinkRouter("app.loshadki.OpenIn-setapp"))
        #expect(KnownBrowsers.isLinkRouter("com.sindresorhus.Velja"))
        #expect(!KnownBrowsers.isLinkRouter("com.brave.Browser"))
    }

    @Test func popularBrowsersComeFirstThenTheRestInOrder() {
        let installed = [
            "com.openai.codex", "com.brave.Browser", "dev.openarc.OpenArc", "com.apple.Safari",
        ]
        #expect(
            KnownBrowsers.ranked(installed) == [
                "com.apple.Safari", "com.brave.Browser", "com.openai.codex", "dev.openarc.OpenArc",
            ])
    }
}
