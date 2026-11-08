import Foundation
import SwitchmanCore

let usage = """
    usage: switchman <command> [options] [--home <dir>]

    commands:
      explain <url> [--source <bundleID>]   show where a link would open, and why
      rules list|validate                   print or check rules.json
      --version                             print the version

    --home defaults to ~/Library/Application Support/Switchman
    """

func fail(_ message: String, status: Int32) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(status)
}

let argv = Array(CommandLine.arguments.dropFirst())

do {
    let arguments = try Arguments(Array(argv.dropFirst()))
    switch argv.first {
    case "explain": try explain(arguments)
    case "rules": try rules(arguments)
    case "--version": print("switchman \(Switchman.version)")
    case "--help", "-h": print(usage)
    default: throw CLIError.usage("")
    }
} catch let error as CLIError {
    let message = error.message.isEmpty ? usage : "switchman: \(error.message)"
    fail(message, status: error.status)
} catch {
    fail("switchman: \(error)", status: 1)
}
