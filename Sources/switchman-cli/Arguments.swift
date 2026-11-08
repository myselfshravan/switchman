import Foundation
import SwitchmanCore

/// Exit with `sysexits.h` codes: 64 for bad usage, 65 for bad input data.
enum CLIError: Error {
    case usage(String)
    case data(String)

    var status: Int32 {
        switch self {
        case .usage: 64
        case .data: 65
        }
    }

    var message: String {
        switch self {
        case .usage(let text), .data(let text): text
        }
    }
}

/// `switchman <command> [positional…] [--name value…]`.
struct Arguments {
    var positional: [String] = []
    var options: [String: String] = [:]

    init(_ arguments: [String]) throws {
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            if argument.hasPrefix("--") {
                guard let value = iterator.next() else {
                    throw CLIError.usage("missing value for \(argument)")
                }
                options[String(argument.dropFirst(2))] = value
            } else {
                positional.append(argument)
            }
        }
    }

    var location: StoreLocation {
        options["home"].map { StoreLocation(base: URL(fileURLWithPath: $0)) } ?? .default
    }

    /// The rules in `rules.json`; none if the file does not exist yet.
    func loadRules() throws -> [Rule] {
        var store = RuleStore(location: location)
        store.reload()
        if let error = store.lastError { throw CLIError.data("cannot read \(error)") }
        return store.rules
    }
}
