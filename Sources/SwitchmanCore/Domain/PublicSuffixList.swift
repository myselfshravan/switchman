import Foundation

/// Finds the registrable domain ("eTLD+1") of a host using the Public Suffix List rules
/// (https://publicsuffix.org/list/): plain, wildcard (`*.ck`) and exception (`!www.ck`) rules,
/// with the implicit `*` rule for unknown TLDs.
public struct PublicSuffixList: Sendable {
    private let rules: Set<String>
    private let wildcards: Set<String>
    private let exceptions: Set<String>

    public init(text: String) {
        var rules = Set<String>()
        var wildcards = Set<String>()
        var exceptions = Set<String>()
        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces).lowercased()
            if line.isEmpty || line.hasPrefix("//") { continue }
            if line.hasPrefix("!") {
                exceptions.insert(String(line.dropFirst()))
            } else if line.hasPrefix("*.") {
                wildcards.insert(String(line.dropFirst(2)))
            } else {
                rules.insert(line)
            }
        }
        self.rules = rules
        self.wildcards = wildcards
        self.exceptions = exceptions
    }

    /// The list vendored in `Resources/public_suffix_list.dat`.
    public static let bundled: PublicSuffixList = {
        let url = Bundle.module.url(forResource: "public_suffix_list", withExtension: "dat")!
        return PublicSuffixList(text: try! String(contentsOf: url, encoding: .utf8))
    }()

    /// The registrable domain of `host`. IP addresses, single-label hosts and hosts that are
    /// themselves public suffixes map to themselves.
    public func registrableDomain(for host: String) -> String {
        if Self.isIPAddress(host) { return host }
        let labels = host.split(separator: ".").map(String.init)
        let suffixLength = publicSuffixLength(labels)
        guard labels.count > suffixLength else { return host }
        return labels.suffix(suffixLength + 1).joined(separator: ".")
    }

    /// Number of trailing labels that form the public suffix (at least 1).
    private func publicSuffixLength(_ labels: [String]) -> Int {
        var longest = 1
        for start in labels.indices {
            let candidate = labels[start...].joined(separator: ".")
            let length = labels.count - start
            if exceptions.contains(candidate) { return length - 1 }
            if rules.contains(candidate) { longest = max(longest, length) }
            if start > labels.startIndex, wildcards.contains(candidate) {
                longest = max(longest, length + 1)
            }
        }
        return longest
    }

    private static func isIPAddress(_ host: String) -> Bool {
        host.contains(":") || host.allSatisfy { $0.isNumber || $0 == "." }
    }
}
