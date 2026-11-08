import Carbon.HIToolbox

/// Preset global shortcuts for "re-open last link in…". Carbon hot keys need no
/// Accessibility permission.
enum HotKeyChoice: String, Codable, CaseIterable, Identifiable {
    case off, controlOptionCommandO, controlOptionCommandL, controlOptionCommandR

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off: "Off"
        case .controlOptionCommandO: "⌃⌥⌘O"
        case .controlOptionCommandL: "⌃⌥⌘L"
        case .controlOptionCommandR: "⌃⌥⌘R"
        }
    }

    fileprivate var keyCode: Int? {
        switch self {
        case .off: nil
        case .controlOptionCommandO: kVK_ANSI_O
        case .controlOptionCommandL: kVK_ANSI_L
        case .controlOptionCommandR: kVK_ANSI_R
        }
    }
}

@MainActor
final class HotKey {
    private var ref: EventHotKeyRef?
    private static var action: (() -> Void)?
    private static var handlerInstalled = false

    func register(_ choice: HotKeyChoice, action: @escaping () -> Void) {
        unregister()
        guard let keyCode = choice.keyCode else { return }
        Self.action = action
        Self.installHandlerOnce()
        let id = EventHotKeyID(signature: OSType(0x5357_4D4E), id: 1)  // 'SWMN'
        RegisterEventHotKey(
            UInt32(keyCode), UInt32(cmdKey | optionKey | controlKey), id,
            GetApplicationEventTarget(), 0, &ref)
    }

    func unregister() {
        if let ref { UnregisterEventHotKey(ref) }
        ref = nil
    }

    private static func installHandlerOnce() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var type = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ in
                MainActor.assumeIsolated { HotKey.action?() }
                return noErr
            }, 1, &type, nil, nil)
    }
}
