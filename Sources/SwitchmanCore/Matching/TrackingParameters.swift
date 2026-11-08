import Foundation

/// Removes well-known click-tracking query parameters before a link is opened (opt-in).
public enum TrackingParameters {
    public static let prefixes = ["utm_"]
    public static let names: Set<String> = [
        "fbclid", "gclid", "dclid", "gbraid", "wbraid", "msclkid", "yclid", "twclid", "igshid",
        "mc_cid", "mc_eid", "_hsenc", "_hsmi", "mkt_tok",
    ]

    public static func strip(_ url: String) -> String {
        guard var components = URLComponents(string: url), let items = components.queryItems
        else { return url }
        let kept = items.filter { item in
            !names.contains(item.name) && !prefixes.contains { item.name.hasPrefix($0) }
        }
        guard kept.count != items.count else { return url }
        components.queryItems = kept.isEmpty ? nil : kept
        return components.string ?? url
    }
}
