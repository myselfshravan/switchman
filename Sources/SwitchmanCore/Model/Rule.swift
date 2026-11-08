import Foundation

public enum RuleAction: Hashable, Sendable {
    case open(BrowserTarget)
    /// The domain is known to be ambiguous: always show the picker.
    case alwaysAsk
}

public enum Origin: String, Codable, Sendable {
    case manual, learned, imported
}

/// One routing rule. `rules.json` holds an ordered array of these; the first match wins.
public struct Rule: Hashable, Sendable, Identifiable {
    public var id: UUID
    public var pattern: Pattern
    /// Only match links opened from this app. nil = any source.
    public var sourceAppBundleID: String?
    public var action: RuleAction
    public var enabled: Bool
    public var origin: Origin
    public var note: String?

    public init(
        id: UUID = UUID(), pattern: Pattern, sourceAppBundleID: String? = nil, action: RuleAction,
        enabled: Bool = true, origin: Origin = .manual, note: String? = nil
    ) {
        self.id = id
        self.pattern = pattern
        self.sourceAppBundleID = sourceAppBundleID
        self.action = action
        self.enabled = enabled
        self.origin = origin
        self.note = note
    }
}

/// Encoded as `"open": {browser}` or `"alwaysAsk": true`, inline in the enclosing object.
extension RuleAction: Codable {
    private enum CodingKeys: String, CodingKey {
        case open, alwaysAsk
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let target = try c.decodeIfPresent(BrowserTarget.self, forKey: .open)
        let alwaysAsk = try c.decodeIfPresent(Bool.self, forKey: .alwaysAsk) ?? false
        switch (target, alwaysAsk) {
        case (let target?, false): self = .open(target)
        case (nil, true): self = .alwaysAsk
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .open, in: c,
                debugDescription: "rule needs exactly one of open or alwaysAsk")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .open(let target): try c.encode(target, forKey: .open)
        case .alwaysAsk: try c.encode(true, forKey: .alwaysAsk)
        }
    }
}

/// On disk a rule is one flat object; `id`, `enabled` and `origin` may be omitted when
/// hand-writing it.
extension Rule: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, pattern, sourceApp, enabled, origin, note
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        action = try RuleAction(from: decoder)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        pattern = try c.decode(Pattern.self, forKey: .pattern)
        sourceAppBundleID = try c.decodeIfPresent(String.self, forKey: .sourceApp)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        origin = try c.decodeIfPresent(Origin.self, forKey: .origin) ?? .manual
        note = try c.decodeIfPresent(String.self, forKey: .note)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(pattern, forKey: .pattern)
        try c.encodeIfPresent(sourceAppBundleID, forKey: .sourceApp)
        try action.encode(to: encoder)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(origin, forKey: .origin)
        try c.encodeIfPresent(note, forKey: .note)
    }
}
