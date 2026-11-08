import AppKit
import SwitchmanCore

/// One row in the picker: a browser app, or one profile of a Chromium browser.
struct BrowserChoice: Identifiable {
    var target: BrowserTarget
    var title: String
    var appURL: URL
    var icon: NSImage

    var id: BrowserTarget { target }
}

/// Finds installed browsers (every app that opens https, except Switchman and other link
/// routers), popular ones first, and for known Chromium browsers their profiles from `Local State`.
@MainActor
enum BrowserDiscovery {
    static func discover() -> [BrowserChoice] {
        let probe = URL(string: "https://example.com")!
        var apps: [String: URL] = [:]
        for appURL in NSWorkspace.shared.urlsForApplications(toOpen: probe) {
            guard let bundleID = Bundle(url: appURL)?.bundleIdentifier,
                bundleID != Bundle.main.bundleIdentifier, !KnownBrowsers.isLinkRouter(bundleID),
                apps[bundleID] == nil
            else { continue }
            apps[bundleID] = appURL
        }
        return KnownBrowsers.ranked(Array(apps.keys).sorted()).flatMap { bundleID in
            let appURL = apps[bundleID]!
            let name = appName(at: appURL)
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            let profiles = chromiumProfiles(bundleID: bundleID)
            return ChromiumProfiles.targets(bundleID: bundleID, profiles: profiles).map { target in
                let profile = profiles.first { $0.directory == target.profileDirectory }
                let title = profile.map { "\(name) — \($0.name)" } ?? name
                return BrowserChoice(target: target, title: title, appURL: appURL, icon: icon)
            }
        }
    }

    /// Display name of any installed app, for explanations ("source: Slack").
    static func appName(bundleID: String) -> String {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID).map(appName(at:))
            ?? bundleID
    }

    private static func appName(at url: URL) -> String {
        FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")
    }

    private static func chromiumProfiles(bundleID: String) -> [ChromiumProfile] {
        guard let browser = ChromiumBrowser.known.first(where: { $0.bundleID == bundleID }) else {
            return []
        }
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let localState = support.appendingPathComponent(browser.userDataPath)
            .appendingPathComponent("Local State")
        return (try? Data(contentsOf: localState)).flatMap {
            try? ChromiumProfiles.parse(localState: $0)
        } ?? []
    }
}

/// Opens links in a specific browser (and profile).
@MainActor
enum BrowserLauncher {
    /// For a Chromium profile, launches a new instance with `--profile-directory`; Chromium
    /// hands the URL to the already-running browser, which opens it in that profile. A plain
    /// open would ignore the arguments when the browser is already running.
    static func open(
        _ url: URL, in choice: BrowserChoice, completion: @escaping @MainActor (Error?) -> Void
    ) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        let done: @Sendable (NSRunningApplication?, Error?) -> Void = { _, error in
            Task { @MainActor in completion(error) }
        }
        if let profile = choice.target.profileDirectory {
            configuration.createsNewApplicationInstance = true
            configuration.arguments = ["--profile-directory=\(profile)", url.absoluteString]
            NSWorkspace.shared.openApplication(
                at: choice.appURL, configuration: configuration, completionHandler: done)
        } else {
            NSWorkspace.shared.open(
                [url], withApplicationAt: choice.appURL, configuration: configuration,
                completionHandler: done)
        }
    }
}

/// Whether Switchman is the system default browser, and making it so.
@MainActor
enum DefaultBrowser {
    static var isSwitchman: Bool {
        let probe = URL(string: "https://example.com")!
        return NSWorkspace.shared.urlForApplication(toOpen: probe).flatMap {
            Bundle(url: $0)?.bundleIdentifier
        } == Bundle.main.bundleIdentifier
    }

    /// macOS asks the user to confirm.
    static func makeSwitchmanDefault(completion: @escaping @MainActor () -> Void) {
        NSWorkspace.shared.setDefaultApplication(
            at: Bundle.main.bundleURL, toOpenURLsWithScheme: "http"
        ) { _ in
            Task { @MainActor in
                NSWorkspace.shared.setDefaultApplication(
                    at: Bundle.main.bundleURL, toOpenURLsWithScheme: "https"
                ) { _ in Task { @MainActor in completion() } }
            }
        }
    }
}
