import Foundation

/// `decisions.jsonl`: one JSON `Decision` per line, append-only, capped at `cap` lines by
/// dropping the oldest. Unreadable lines are skipped rather than failing the whole log.
public struct DecisionLog: Sendable {
    public let location: StoreLocation
    public let cap: Int
    private var lineCount: Int?

    public init(location: StoreLocation, cap: Int = 20_000) {
        self.location = location
        self.cap = cap
    }

    public mutating func append(_ decision: Decision) throws {
        let url = location.decisions
        let line = try Self.encoder.encode(decision) + Data("\n".utf8)
        let count = try lineCount ?? readLines().count
        if count >= cap {
            let kept = try readLines().suffix(cap - 1).map { Data($0.utf8) + Data("\n".utf8) }
            try (kept.reduce(Data(), +) + line).write(to: url, options: .atomic)
            lineCount = cap
            return
        }
        if FileManager.default.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
        } else {
            try FileManager.default.createDirectory(
                at: location.base, withIntermediateDirectories: true)
            try line.write(to: url, options: .atomic)
        }
        lineCount = count + 1
    }

    public func readAll() throws -> [Decision] {
        try readLines().compactMap { try? Self.decoder.decode(Decision.self, from: Data($0.utf8)) }
    }

    private func readLines() throws -> [String] {
        let url = location.decisions
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try String(contentsOf: url, encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
