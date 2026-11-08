import ServiceManagement
import SwiftUI
import SwitchmanCore

struct GeneralTab: View {
    @Bindable var model: AppModel
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            if !model.preferences.onboarded { welcome }
            Section("Default browser") {
                if model.isDefaultBrowser {
                    Label("Switchman is your default browser", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Make Switchman the Default Browser…") { model.makeDefaultBrowser() }
                }
            }
            Section("Behaviour") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { setLaunchAtLogin($1) }
                if let loginError { Text(loginError).foregroundStyle(.red).font(.caption) }
                Toggle(
                    "Strip tracking parameters (utm_*, fbclid, gclid…)",
                    isOn: $model.preferences.stripTracking)
                Picker("Re-open last link in another browser", selection: $model.preferences.hotKey)
                {
                    ForEach(HotKeyChoice.allCases) { Text($0.label).tag($0) }
                }
                Text("Hold ⌥ Option while clicking a link to always get the picker.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Privacy") {
                Text(
                    "Everything stays on this Mac. Switchman has no network code. The decision log "
                        + "keeps only scheme, host and path — never query strings or fragments."
                )
                .font(.caption)
                Button("Show Data Folder in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([model.store.location.base])
                }
            }
        }
        .formStyle(.grouped)
    }

    private var welcome: some View {
        Section("Welcome to Switchman") {
            Text(
                "1. Make Switchman your default browser.\n2. Optionally import history (Import tab) "
                    + "to get suggestions on day one.\n3. Click links — pick a browser once, accept "
                    + "the rules Switchman suggests."
            )
            Button("Got it") { model.preferences.onboarded = true }
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = "\(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
