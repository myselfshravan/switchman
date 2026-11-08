// Prints the on-screen window IDs owned by a process, for scripted screenshots of only that
// app (`screencapture -l <id>`). Usage: swift scripts/window_ids.swift <pid>
import CoreGraphics

let pid = Int32(CommandLine.arguments[1])!
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for window in windows where window[kCGWindowOwnerPID as String] as? Int32 == pid {
    let bounds = window[kCGWindowBounds as String] as? [String: Any] ?? [:]
    print(
        window[kCGWindowNumber as String]!, window[kCGWindowLayer as String]!, bounds["Width"]!,
        bounds["Height"]!)
}
