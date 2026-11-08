/// What a rule matches. Encoded in `rules.json` as a single-key object, e.g. `{"host": "github.com"}`.
public enum Pattern: Hashable, Sendable {
    /// Exact host, e.g. `github.com`. Include `:port` to match only that port.
    case host(String)
    /// `*.atlassian.net`: any subdomain, and the apex itself.
    case hostWildcard(String)
    /// `github.com/acme/`: host plus leading whole path segments. Host is case-insensitive.
    case urlPrefix(String)
    /// Searched in `URLKey.description` (`host[:port]/path?hints`). Anchor it yourself.
    case regex(String)
}

extension Pattern: Codable {
    private enum CodingKeys: String, CodingKey {
        case host, hostWildcard, urlPrefix, regex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard container.allKeys.count == 1, let kind = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription:
                        "pattern needs exactly one of host, hostWildcard, urlPrefix, regex"))
        }
        let value = try container.decode(String.self, forKey: kind)
        switch kind {
        case .host: self = .host(value)
        case .hostWildcard: self = .hostWildcard(value)
        case .urlPrefix: self = .urlPrefix(value)
        case .regex: self = .regex(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .host(let value): try container.encode(value, forKey: .host)
        case .hostWildcard(let value): try container.encode(value, forKey: .hostWildcard)
        case .urlPrefix(let value): try container.encode(value, forKey: .urlPrefix)
        case .regex(let value): try container.encode(value, forKey: .regex)
        }
    }
}

extension Pattern: CustomStringConvertible {
    public var description: String {
        switch self {
        case .host(let host): host
        case .hostWildcard(let host): host
        case .urlPrefix(let prefix): prefix.hasSuffix("/") ? prefix + "*" : prefix + "/*"
        case .regex(let regex): "/\(regex)/"
        }
    }
}
