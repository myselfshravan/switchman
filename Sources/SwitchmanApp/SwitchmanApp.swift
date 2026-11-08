import SwiftUI
import SwitchmanCore

@main
struct SwitchmanApp: App {
    var body: some Scene {
        MenuBarExtra("Switchman", systemImage: "arrow.triangle.branch") {
            Text("Switchman \(Switchman.version)")
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
