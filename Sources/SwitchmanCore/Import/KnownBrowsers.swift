/// Defaults for the picker: real browsers people use most go first, and other link-routing
/// apps are left out (sending a link from one router to another helps no one).
public enum KnownBrowsers {
    public static let popular = [
        "com.apple.Safari", "com.google.Chrome", "com.brave.Browser", "org.mozilla.firefox",
        "company.thebrowser.Browser", "com.microsoft.edgemac", "com.vivaldi.Vivaldi",
        "com.operasoftware.Opera", "com.kagi.kagimacOS", "app.zen-browser.zen",
        "org.chromium.Chromium", "com.duckduckgo.macos.browser",
    ]

    /// Bundle ID prefixes of Browserosaurus, OpenIn, Velja, Finicky and Choosy.
    public static let linkRouters = [
        "com.browserosaurus", "app.loshadki.OpenIn", "com.sindresorhus.Velja",
        "se.johnste.finicky", "com.choosyosx.Choosy",
    ]

    public static func isLinkRouter(_ bundleID: String) -> Bool {
        linkRouters.contains { bundleID.hasPrefix($0) }
    }

    /// Popular browsers in `popular` order, then everything else in the given order.
    public static func ranked(_ bundleIDs: [String]) -> [String] {
        let rank = { (id: String) in popular.firstIndex(of: id) ?? popular.count }
        return bundleIDs.enumerated()
            .sorted { (rank($0.element), $0.offset) < (rank($1.element), $1.offset) }
            .map(\.element)
    }
}
