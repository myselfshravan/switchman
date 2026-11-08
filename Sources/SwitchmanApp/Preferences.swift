import Foundation
import SwitchmanCore

/// App settings that are not rules: kept in UserDefaults, not in `rules.json`.
struct Preferences: Codable, Equatable {
    var hidden: Set<BrowserTarget> = []
    /// Picker order; browsers not listed follow in discovery order.
    var order: [BrowserTarget] = []
    var fallback: BrowserTarget?
    var stripTracking = false
    var hotKey: HotKeyChoice = .controlOptionCommandO
    var onboarded = false

    private static let key = "preferences"

    static func load() -> Preferences {
        UserDefaults.standard.data(forKey: key)
            .flatMap { try? JSONDecoder().decode(Preferences.self, from: $0) } ?? Preferences()
    }

    func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(self), forKey: Self.key)
    }

    /// All choices in the user's order (hidden ones included; callers filter).
    func arrange(_ choices: [BrowserChoice]) -> [BrowserChoice] {
        let rank = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        return choices.enumerated()
            .sorted {
                (rank[$0.element.target] ?? order.count + $0.offset)
                    < (rank[$1.element.target] ?? order.count + $1.offset)
            }
            .map(\.element)
    }
}
