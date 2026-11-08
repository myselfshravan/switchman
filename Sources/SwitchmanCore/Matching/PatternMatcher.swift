/// The one URL matcher. Routing, `switchman explain` and the learner all go through here.
extension Pattern {
    public func matches(_ key: URLKey) -> Bool {
        switch self {
        case .host(let host):
            let wanted = Self.normalisedHost(host)
            return wanted == (wanted.contains(":") ? key.authority : key.host)
        case .hostWildcard(let wildcard):
            let apex = Self.wildcardApex(wildcard)
            return key.host == apex || key.host.hasSuffix("." + apex)
        case .urlPrefix(let prefix):
            let (authority, segments) = Self.splitPrefix(prefix)
            return key.authority == authority && key.pathSegments.starts(with: segments)
        case .regex(let source):
            guard let regex = try? Regex(source) else { return false }
            return key.description.contains(regex)
        }
    }

    /// Why this pattern can never match anything sensible, or nil if it is valid.
    public var validationError: String? {
        switch self {
        case .host(let host) where Self.normalisedHost(host).isEmpty:
            return "host is empty"
        case .hostWildcard(let wildcard) where Self.wildcardApex(wildcard).isEmpty:
            return "hostWildcard has no domain"
        case .urlPrefix(let prefix) where Self.splitPrefix(prefix).authority.isEmpty:
            return "urlPrefix has no host"
        case .regex(let source):
            do {
                _ = try Regex(source)
                return nil
            } catch {
                return "invalid regex: \(error)"
            }
        default:
            return nil
        }
    }

    private static func normalisedHost(_ host: String) -> String {
        let lower = host.lowercased()
        return lower.hasPrefix("www.") ? String(lower.dropFirst(4)) : lower
    }

    private static func wildcardApex(_ wildcard: String) -> String {
        let lower = wildcard.lowercased()
        return lower.hasPrefix("*.") ? String(lower.dropFirst(2)) : lower
    }

    /// `"https://WWW.GitHub.com/acme/"` → (`"github.com"`, `["acme"]`).
    private static func splitPrefix(_ prefix: String) -> (authority: String, segments: [String]) {
        let withoutScheme = prefix.split(separator: "://", maxSplits: 1).last.map(String.init) ?? ""
        let parts = withoutScheme.split(separator: "/").map(String.init)
        return (normalisedHost(parts.first ?? ""), Array(parts.dropFirst()))
    }
}

extension Rule {
    public func matches(_ key: URLKey, sourceApp: String?) -> Bool {
        enabled && (sourceAppBundleID == nil || sourceAppBundleID == sourceApp)
            && pattern.matches(key)
    }
}
