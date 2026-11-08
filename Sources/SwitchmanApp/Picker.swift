import AppKit
import SwiftUI
import SwitchmanCore

/// What the picker is currently showing. Keyboard logic lives in Core's `PickerState`.
@MainActor
@Observable
final class PickerViewModel {
    var link = ""
    var source: String?
    /// Text of the remember checkbox; nil hides it.
    var rememberLabel: String?
    var choices: [BrowserChoice] = []
    var state = PickerState(count: 0)
}

/// A borderless, non-activating panel near the cursor. Reused between links so it appears
/// instantly.
@MainActor
final class PickerController {
    typealias Completion = (BrowserChoice?, _ remember: Bool) -> Void

    private let model = PickerViewModel()
    private lazy var panel = makePanel()
    private var completion: Completion?
    private var keyMonitor: Any?

    func show(
        link: String, source: String?, choices: [BrowserChoice], rememberLabel: String?,
        suggested: Int? = nil, completion: @escaping Completion
    ) {
        finish(with: nil)
        model.link = link
        model.source = source
        model.rememberLabel = rememberLabel
        model.choices = choices
        model.state = PickerState(
            count: choices.count, suggested: suggested)
        self.completion = completion

        let size = panel.contentView?.fittingSize ?? NSSize(width: 320, height: 200)
        panel.setContentSize(size)
        panel.setFrameOrigin(origin(for: size))
        panel.makeKeyAndOrderFront(nil)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let key = Self.key(for: event) else { return event }
            self.press(key)
            return nil
        }
    }

    func press(_ key: PickerState.Key) {
        switch model.state.handle(key) {
        case .pick(let index, let remember): finish(with: model.choices[index], remember: remember)
        case .cancel: finish(with: nil)
        case nil: break
        }
    }

    func click(_ index: Int) {
        finish(with: model.choices[index], remember: model.state.remember(for: index))
    }

    /// Takes the completion before hiding the panel: `orderOut` posts `didResignKey`
    /// synchronously, which re-enters here as a cancel and must find nothing left to cancel.
    private func finish(with choice: BrowserChoice?, remember: Bool = false) {
        let completion = self.completion
        self.completion = nil
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        if panel.isVisible { panel.orderOut(nil) }
        completion?(choice, remember)
    }

    private static func key(for event: NSEvent) -> PickerState.Key? {
        if event.modifierFlags.contains(.command) {
            return event.charactersIgnoringModifiers == "r" ? .toggleRemember : nil
        }
        switch Int(event.keyCode) {
        case 53: return .cancel
        case 36, 76: return .confirm
        case 126: return .up
        case 125: return .down
        default: return event.characters.flatMap(Int.init).map { .number($0) }
        }
    }

    /// Just below-right of the mouse, kept on screen.
    private func origin(for size: NSSize) -> NSPoint {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        let x = min(max(mouse.x - 20, visible.minX), visible.maxX - size.width)
        let y = min(max(mouse.y - size.height + 10, visible.minY), visible.maxY - size.height)
        return NSPoint(x: x, y: y)
    }

    private func makePanel() -> NSPanel {
        let panel = KeyPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentView = FirstClickHostingView(
            rootView: PickerView(model: model, controller: self))
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.finish(with: nil) }
        }
        return panel
    }
}

/// Borderless panels refuse key status by default; the picker needs the keyboard.
private final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// The picker sits over another app's window; a click on a row must pick, not just focus.
private final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

struct PickerView: View {
    let model: PickerViewModel
    let controller: PickerController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.link).font(.callout.monospaced()).lineLimit(1).truncationMode(.middle)
                if let source = model.source {
                    Text("from \(source)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            ForEach(Array(model.choices.enumerated()), id: \.element.id) { index, choice in
                row(index, choice)
            }
            if let label = model.rememberLabel {
                Toggle(
                    "\(label)  ⌘R",
                    isOn: Binding(
                        get: { model.state.remember },
                        set: { _ in controller.press(.toggleRemember) })
                )
                .toggleStyle(.checkbox).font(.caption).padding(.horizontal, 8)
            }
        }
        .padding(8)
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func row(_ index: Int, _ choice: BrowserChoice) -> some View {
        Button {
            controller.click(index)
        } label: {
            HStack(spacing: 10) {
                Text(index < 9 ? "\(index + 1)" : " ")
                    .font(.caption.monospaced()).foregroundStyle(.secondary).frame(width: 12)
                Image(nsImage: choice.icon).resizable().frame(width: 22, height: 22)
                Text(choice.title).lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .contentShape(Rectangle())
            .background(
                index == model.state.highlighted ? Color.accentColor.opacity(0.25) : .clear,
                in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
