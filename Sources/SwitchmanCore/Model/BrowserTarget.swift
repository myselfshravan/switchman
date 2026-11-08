/// A browser app, optionally pinned to one of its Chromium profiles (e.g. `"Profile 1"`).
public struct BrowserTarget: Hashable, Codable, Sendable {
    public var bundleID: String
    public var profileDirectory: String?

    public init(bundleID: String, profileDirectory: String? = nil) {
        self.bundleID = bundleID
        self.profileDirectory = profileDirectory
    }
}
