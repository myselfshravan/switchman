import AppKit
import SwiftUI
import SwitchmanCore

@main
struct SwitchmanApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Switchman", systemImage: "arrow.triangle.branch") {
            MenuContent(model: delegate.model, windows: delegate.windows)
        }
    }
}

/// Receives links. Registered before launch finishes so the link that launched us isn't lost.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    lazy var windows = Windows(model: model)

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handleGetURL(_:reply:)),
            forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        model.start()
        if !model.preferences.onboarded { windows.showSettings(tab: .general) }
    }

    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor)
    {
        guard let string = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
            let url = URL(string: string), ["http", "https"].contains(url.scheme?.lowercased())
        else { return }
        let pid = event.attributeDescriptor(forKeyword: AEKeyword(keySenderPIDAttr))?.int32Value
        let source = pid.flatMap { NSRunningApplication(processIdentifier: $0)?.bundleIdentifier }
        let modifiers: Modifiers = NSEvent.modifierFlags.contains(.option) ? .option : []
        model.handle(url, sourceApp: source, modifiers: modifiers)
    }
}

struct MenuContent: View {
    let model: AppModel
    let windows: Windows

    var body: some View {
        if model.isDefaultBrowser {
            Text("✓ Switchman is your default browser")
        } else {
            Button("Make Switchman the Default Browser…") { model.makeDefaultBrowser() }
        }
        if let error = model.lastError {
            Text("⚠︎ \(error)").lineLimit(2)
        }
        Divider()
        if model.recent.isEmpty {
            Text("No links yet")
        } else {
            Text("Recent links")
            ForEach(model.recent) { link in
                Menu("\(link.key.description)  →  \(link.explanation)") { reopenItems(link) }
            }
        }
        if let last = model.recent.first {
            Menu("Re-open Last Link in… (\(model.preferences.hotKey.label))") { reopenItems(last) }
        }
        Divider()
        Button(suggestionsTitle) { windows.showSettings(tab: .suggestions) }
        Button("Settings…") { windows.showSettings(tab: .rules) }
            .keyboardShortcut(",")
        Divider()
        Button("Quit Switchman") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }

    private var suggestionsTitle: String {
        let count = model.suggestions.count + model.importedSuggestions.count
        return count == 0 ? "Suggestions" : "Suggestions (\(count))"
    }

    @ViewBuilder
    private func reopenItems(_ link: RecentLink) -> some View {
        ForEach(model.visibleBrowsers.filter { $0.target != link.target }) { choice in
            Button(choice.title) { model.reopen(link, in: choice.target) }
        }
    }
}
