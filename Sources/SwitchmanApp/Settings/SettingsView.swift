import SwiftUI

struct SettingsView: View {
    let model: AppModel
    @Bindable var selection: TabSelection

    var body: some View {
        TabView(selection: $selection.tab) {
            RulesTab(model: model)
                .tabItem { Label("Rules", systemImage: "list.number") }.tag(SettingsTab.rules)
            SuggestionsTab(model: model)
                .tabItem { Label("Suggestions", systemImage: "lightbulb") }
                .tag(SettingsTab.suggestions)
            BrowsersTab(model: model)
                .tabItem { Label("Browsers", systemImage: "safari") }.tag(SettingsTab.browsers)
            ImportTab(model: model)
                .tabItem { Label("Import", systemImage: "clock.arrow.circlepath") }
                .tag(SettingsTab.importHistory)
            GeneralTab(model: model)
                .tabItem { Label("General", systemImage: "gearshape") }.tag(SettingsTab.general)
        }
        .padding()
        .frame(minWidth: 680, minHeight: 480)
    }
}

/// A warning line shown when something went wrong (e.g. an invalid `rules.json`).
struct ErrorBanner: View {
    let message: String?

    var body: some View {
        if let message {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange).font(.callout).lineLimit(3)
        }
    }
}
