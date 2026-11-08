import AppKit
import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case rules = "Rules"
    case suggestions = "Suggestions"
    case browsers = "Browsers"
    case importHistory = "Import"
    case general = "General"

    var id: String { rawValue }
}

/// The settings window, owned by AppKit so a menu-bar-only app can bring it to the front.
@MainActor
final class Windows {
    private let model: AppModel
    private var settings: NSWindow?
    private let selection = TabSelection()

    init(model: AppModel) {
        self.model = model
    }

    func showSettings(tab: SettingsTab) {
        selection.tab = tab
        model.refresh()
        let window = settings ?? makeSettingsWindow()
        settings = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeSettingsWindow() -> NSWindow {
        let window = NSWindow(
            contentViewController: NSHostingController(
                rootView: SettingsView(model: model, selection: selection)))
        window.title = "Switchman"
        window.setContentSize(NSSize(width: 720, height: 520))
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}

@MainActor
@Observable
final class TabSelection {
    var tab: SettingsTab = .rules
}
