import Foundation

/// The privacy-preserving, normalised form of a web URL that routing and learning work on.
/// Only scheme, host, non-default port, path segments and allow-listed hint query keys survive.
public struct URLKey: Hashable, Codable, Sendable {
    public var scheme: String
    public var host: String
    public var port: Int?
    public var registrableDomain: String
    public var pathSegments: [String]
    public var hints: [String: String]

    /// Query keys that signal which account a link is for, so they are kept.
    public static let hintKeys: Set<String> = ["authuser", "u"]

    public init(
        scheme: String, host: String, port: Int? = nil, registrableDomain: String,
        pathSegments: [String] = [], hints: [String: String] = [:]
    ) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.registrableDomain = registrableDomain
        self.pathSegments = pathSegments
        self.hints = hints
    }

    /// Normalises `string`, or returns nil if it is not an `http`/`https` URL with a host.
    public init?(_ string: String, suffixes: PublicSuffixList) {
        guard let components = URLComponents(string: string),
            let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https",
            var host = components.host?.lowercased(), !host.isEmpty
        else { return nil }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        let port = components.port.flatMap { [80, 443].contains($0) ? nil : $0 }
        let segments = components.percentEncodedPath.split(separator: "/").map(String.init)
        var hints: [String: String] = [:]
        for item in components.queryItems ?? [] where Self.hintKeys.contains(item.name) {
            hints[item.name] = item.value ?? ""
        }
        self.init(
            scheme: scheme, host: host, port: port,
            registrableDomain: suffixes.registrableDomain(for: host),
            pathSegments: segments, hints: hints)
    }

    /// `host` plus `:port` when the port is non-default.
    public var authority: String { port.map { "\(host):\($0)" } ?? host }
}

extension URLKey: CustomStringConvertible {
    /// The string patterns match against: `authority/seg/seg?hint=v` with hints sorted by key.
    public var description: String {
        let path = pathSegments.map { "/" + $0 }.joined()
        let query = hints.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
        return authority + path + (query.isEmpty ? "" : "?" + query.joined(separator: "&"))
    }
}
