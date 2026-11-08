import Foundation

/// One-line, human-readable forms shared by the CLI and the app.
extension RuleAction: CustomStringConvertible {
    /// `com.google.Chrome (Profile 1)` or `ask`.
    public var description: String {
        switch self {
        case .open(let target): target.bundleID + (target.profileDirectory.map { " (\($0))" } ?? "")
        case .alwaysAsk: "ask"
        }
    }
}

extension Rule {
    /// `github.com/acme/*  → com.brave.Browser  from com.tinyspeck.slackmacgap`
    public var summary: String {
        var parts = ["\(pattern)", "→ \(action)"]
        if let sourceAppBundleID { parts.append("from \(sourceAppBundleID)") }
        if !enabled { parts.append("(disabled)") }
        return parts.joined(separator: "  ")
    }
}

extension Suggestion {
    /// `a.com  → com.brave.Browser  (support 12.5, 97%, imported)  e.g. a.com/x`
    public var summary: String {
        let support =
            self.support.rounded() == self.support
            ? String(Int(self.support)) : String(format: "%.1f", self.support)
        var stats = ["support \(support)", "\(Int((confidence * 100).rounded()))%"]
        if origin == .imported { stats.append("imported") }
        var parts = [makeRule().summary, "(\(stats.joined(separator: ", ")))"]
        if let example = examples.first { parts.append("e.g. \(example)") }
        return parts.joined(separator: "  ")
    }
}
