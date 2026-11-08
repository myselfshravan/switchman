import Foundation

/// One record of where a link ended up. Live clicks and imported history share this type,
/// so one suggestion engine learns from both.
public struct Decision: Hashable, Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case picked, autoRouted, corrected, imported
    }

    public var date: Date
    public var key: URLKey
    public var sourceAppBundleID: String?
    public var chosen: BrowserTarget
    public var kind: Kind
    public var weight: Double

    public init(
        date: Date, key: URLKey, sourceAppBundleID: String? = nil, chosen: BrowserTarget,
        kind: Kind, weight: Double? = nil
    ) {
        self.date = date
        self.key = key
        self.sourceAppBundleID = sourceAppBundleID
        self.chosen = chosen
        self.kind = kind
        self.weight = weight ?? (kind == .corrected ? 3 : 1)
    }

    /// `log2(1 + visitCount)`, so a page visited 1000 times counts ~10, not 1000.
    public static func importedWeight(visitCount: Int) -> Double {
        log2(1 + Double(max(0, visitCount)))
    }
}
