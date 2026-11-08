import Foundation
import SwitchmanCore

let usage = """
    usage: switchman <command> [options]

    commands:
      --version    print the version
    """

let arguments = Array(CommandLine.arguments.dropFirst())

switch arguments.first {
case "--version":
    print("switchman \(Switchman.version)")
case "--help", "-h":
    print(usage)
default:
    FileHandle.standardError.write(Data((usage + "\n").utf8))
    exit(64)  // EX_USAGE
}
