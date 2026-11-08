import Foundation

/// A Chromium-based browser Switchman knows how to read profiles and history for.
public struct ChromiumBrowser: Sendable {
    public var bundleID: String
    public var name: String
    /// Under `~/Library/Application Support`.
    public var userDataPath: String

    public static let known: [ChromiumBrowser] = [
        ChromiumBrowser(
            bundleID: "com.google.Chrome", name: "Chrome", userDataPath: "Google/Chrome"),
        ChromiumBrowser(
            bundleID: "com.brave.Browser", name: "Brave",
            userDataPath: "BraveSoftware/Brave-Browser"),
        ChromiumBrowser(
            bundleID: "com.microsoft.edgemac", name: "Edge", userDataPath: "Microsoft Edge"),
        ChromiumBrowser(bundleID: "com.vivaldi.Vivaldi", name: "Vivaldi", userDataPath: "Vivaldi"),
        ChromiumBrowser(
            bundleID: "org.chromium.Chromium", name: "Chromium", userDataPath: "Chromium"),
    ]

    /// Case-insensitive lookup by display name, e.g. `brave`.
    public static func named(_ name: String) -> ChromiumBrowser? {
        known.first { $0.name.lowercased() == name.lowercased() }
    }
}

public struct ChromiumProfile: Hashable, Sendable {
    /// Directory under the user-data dir, passed as `--profile-directory`, e.g. `Profile 1`.
    public var directory: String
    /// Name the user gave the profile.
    public var name: String

    public init(directory: String, name: String) {
        self.directory = directory
        self.name = name
    }
}

public enum ChromiumProfiles {
    /// Profiles from a `Local State` file's `profile.info_cache`, `Default` first, then by number.
    public static func parse(localState: Data) throws -> [ChromiumProfile] {
        struct LocalState: Decodable {
            struct Profile: Decodable { var info_cache: [String: Info]? }
            struct Info: Decodable { var name: String? }
            var profile: Profile?
        }
        let cache = try JSONDecoder().decode(LocalState.self, from: localState).profile?.info_cache
        return (cache ?? [:])
            .map { ChromiumProfile(directory: $0.key, name: $0.value.name ?? $0.key) }
            .sorted { order($0.directory) < order($1.directory) }
    }

    /// One target per profile, or a profile-less target when there is nothing to choose.
    /// Picker, rules and history import all use this, so their targets compare equal.
    public static func targets(bundleID: String, profiles: [ChromiumProfile]) -> [BrowserTarget] {
        guard profiles.count > 1 else { return [BrowserTarget(bundleID: bundleID)] }
        return profiles.map { BrowserTarget(bundleID: bundleID, profileDirectory: $0.directory) }
    }

    private static func order(_ directory: String) -> (Int, String) {
        if directory == "Default" { return (-1, "") }
        let number = Int(directory.replacingOccurrences(of: "Profile ", with: "")) ?? Int.max
        return (number, directory)
    }
}
