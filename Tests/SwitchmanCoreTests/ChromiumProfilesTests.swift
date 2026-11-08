import Foundation
import SwitchmanCore
import Testing

@Suite struct ChromiumProfilesTests {
    let localState = Data(
        #"""
        {"profile": {"info_cache": {
            "Profile 10": {"name": "Side project"},
            "Profile 2": {"name": "Work"},
            "Default": {"name": "Personal", "avatar_icon": "x"}
        }, "last_used": "Default"}, "browser": {}}
        """#.utf8)

    @Test func parsesProfilesDefaultFirstThenNumeric() throws {
        let profiles = try ChromiumProfiles.parse(localState: localState)
        #expect(profiles.map(\.directory) == ["Default", "Profile 2", "Profile 10"])
        #expect(profiles.map(\.name) == ["Personal", "Work", "Side project"])
    }

    @Test func missingInfoCacheMeansNoProfiles() throws {
        #expect(try ChromiumProfiles.parse(localState: Data("{}".utf8)).isEmpty)
    }

    @Test func invalidJSONThrows() {
        #expect(throws: (any Error).self) {
            try ChromiumProfiles.parse(localState: Data("nope".utf8))
        }
    }

    @Test func singleProfileBrowsersAreTargetedWithoutAProfile() {
        let one = [ChromiumProfile(directory: "Default", name: "Me")]
        #expect(ChromiumProfiles.targets(bundleID: "com.brave.Browser", profiles: one) == [brave])
        #expect(ChromiumProfiles.targets(bundleID: "com.brave.Browser", profiles: []) == [brave])
    }

    @Test func multiProfileBrowsersGetOneTargetPerProfile() throws {
        let profiles = try ChromiumProfiles.parse(localState: localState)
        #expect(
            ChromiumProfiles.targets(bundleID: "com.google.Chrome", profiles: profiles).map(
                \.profileDirectory) == ["Default", "Profile 2", "Profile 10"])
    }

    @Test func knownBrowsersIncludeChromeAndBrave() {
        let chrome = ChromiumBrowser.known.first { $0.bundleID == "com.google.Chrome" }
        #expect(chrome?.userDataPath == "Google/Chrome")
        let brave = ChromiumBrowser.known.first { $0.bundleID == "com.brave.Browser" }
        #expect(brave?.userDataPath == "BraveSoftware/Brave-Browser")
        #expect(ChromiumBrowser.named("brave")?.bundleID == "com.brave.Browser")
    }
}
