import Foundation
import Testing

/// Runs the built `switchman` binary and captures its output.
func runCLI(_ arguments: [String]) throws -> (status: Int32, stdout: String, stderr: String) {
    let process = Process()
    process.executableURL = productsDirectory.appendingPathComponent("switchman")
    process.arguments = arguments
    let out = Pipe()
    let err = Pipe()
    process.standardOutput = out
    process.standardError = err
    try process.run()
    process.waitUntilExit()
    let stdout = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    let stderr = String(decoding: err.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    return (process.terminationStatus, stdout, stderr)
}

/// The SwiftPM build products directory that holds the test bundle and the CLI binary.
/// Found from this test image's own path, which lives inside `<products>/*.xctest/`.
let productsDirectory: URL = {
    var info = Dl_info()
    dladdr(#dsohandle, &info)
    var url = URL(fileURLWithPath: String(cString: info.dli_fname))
    while url.pathExtension != "xctest" && url.path != "/" {
        url.deleteLastPathComponent()
    }
    return url.deletingLastPathComponent()
}()

@Test func versionFlagPrintsVersion() throws {
    let result = try runCLI(["--version"])
    #expect(result.status == 0)
    #expect(result.stdout.hasPrefix("switchman "))
}

@Test func unknownCommandFailsWithUsage() throws {
    let result = try runCLI(["frobnicate"])
    #expect(result.status == 64)
    #expect(result.stderr.contains("usage: switchman"))
}
