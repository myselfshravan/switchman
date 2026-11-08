import AppKit
import Observation
import SwitchmanCore

/// A link that came in, kept in memory only (the decision log never stores full URLs).
struct RecentLink: Identifiable {
    let id = UUID()
    var url: URL
    var key: URLKey
    var sourceApp: String?
    var target: BrowserTarget
    var explanation: String
}

/// Everything the app knows and does: Core does the thinking, this performs the side effects.
@MainActor
@Observable
final class AppModel {
    private(set) var store: RuleStore
    private var log: DecisionLog
    private(set) var browsers: [BrowserChoice] = []
    private(set) var recent: [RecentLink] = []
    private(set) var suggestions: [Suggestion] = []
    private(set) var disagreements: [Disagreement] = []
    /// Suggestions at the picker's lower bar, refreshed with `suggestions`.
    private var hints: [Suggestion] = []
    var importedSuggestions: [Suggestion] = []
    private(set) var isDefaultBrowser = false
    private(set) var lastError: String?
    var preferences = Preferences.load() {
        didSet {
            preferences.save()
            if preferences.hotKey != oldValue.hotKey { registerHotKey() }
        }
    }

    let picker = PickerController()
    private let hotKey = HotKey()
    private var watcher: DirectoryWatcher?

    init() {
        let home = ProcessInfo.processInfo.environment["SWITCHMAN_HOME"]
        let location = home.map { StoreLocation(base: URL(fileURLWithPath: $0)) } ?? .default
        store = RuleStore(location: location)
        log = DecisionLog(location: location)
    }

    func start() {
        try? FileManager.default.createDirectory(
            at: store.location.base, withIntermediateDirectories: true)
        reloadRules()
        refresh()
        watcher = DirectoryWatcher(url: store.location.base) { [weak self] in self?.reloadRules() }
        registerHotKey()
    }

    /// Re-reads things that can change outside the app.
    func refresh() {
        browsers = BrowserDiscovery.discover()
        isDefaultBrowser = DefaultBrowser.isSwitchman
        refreshSuggestions()
    }

    var visibleBrowsers: [BrowserChoice] {
        preferences.arrange(browsers).filter { !preferences.hidden.contains($0.target) }
    }

    func appName(_ bundleID: String) -> String {
        browsers.first { $0.target.bundleID == bundleID }?.title
            .components(separatedBy: " — ").first ?? BrowserDiscovery.appName(bundleID: bundleID)
    }

    func explain(_ result: RouteResult) -> String {
        result.explanation(appName: appName)
    }

    // MARK: Routing

    /// Entry point for every incoming link. Never drops one: failures go to the fallback.
    func handle(_ url: URL, sourceApp: String?, modifiers: Modifiers) {
        let opened =
            preferences.stripTracking
            ? URL(string: TrackingParameters.strip(url.absoluteString)) ?? url : url
        guard let key = URLKey(opened.absoluteString, suffixes: .bundled) else { return }
        let result = Router.route(
            key, sourceApp: sourceApp, rules: store.rules, modifiers: modifiers)
        switch result {
        case .open(let target, _):
            open(opened, key: key, sourceApp: sourceApp, in: target, kind: .autoRouted, result)
        case .ask:
            showPicker(for: opened, key: key, sourceApp: sourceApp, reason: result)
        }
    }

    /// Asks, starting from what the learner already believes: a hinted browser is highlighted
    /// with "always use" pre-ticked for it, so Return accepts the learned rule. Without a hint
    /// the checkbox offers a domain-wide rule, unticked.
    private func showPicker(for url: URL, key: URLKey, sourceApp: String?, reason: RouteResult) {
        let choices = visibleBrowsers
        guard !choices.isEmpty else { return openInFallback(url) }
        let hint = PickerHint.find(for: key, sourceApp: sourceApp, in: hints)
        let hinted = hint.flatMap { h in choices.firstIndex { $0.target == h.target } }
        picker.show(
            link: key.description, source: sourceApp.map(appName), choices: choices,
            rememberLabel: hinted != nil ? hint?.label : "Remember for \(key.registrableDomain)",
            suggested: hinted
        ) { [weak self] choice, remember in
            guard let self, let choice else { return }
            if remember {
                let learned = hint.flatMap { $0.target == choice.target ? $0.rule : nil }
                self.addRule(learned ?? .remembering(key, opensIn: choice.target))
            }
            self.open(url, key: key, sourceApp: sourceApp, in: choice.target, kind: .picked, reason)
        }
    }

    private func open(
        _ url: URL, key: URLKey, sourceApp: String?, in target: BrowserTarget,
        kind: Decision.Kind, _ result: RouteResult
    ) {
        guard
            let choice = browsers.first(where: { $0.target == target })
                ?? browsers.first(where: { $0.target.bundleID == target.bundleID })
        else { return openInFallback(url) }
        BrowserLauncher.open(url, in: choice) { [weak self] error in
            if error != nil { self?.openInFallback(url) }
        }
        record(
            Decision(date: .now, key: key, sourceAppBundleID: sourceApp, chosen: target, kind: kind)
        )
        let explanation = kind == .picked ? "\(choice.title) — picked" : explain(result)
        recent.insert(
            RecentLink(
                url: url, key: key, sourceApp: sourceApp, target: target, explanation: explanation),
            at: 0)
        recent = Array(recent.prefix(10))
    }

    /// The user's fallback browser, else Safari. Never Switchman itself, so no loops.
    private func openInFallback(_ url: URL) {
        let fallback = preferences.fallback.flatMap { f in browsers.first { $0.target == f } }
        let appURL =
            fallback?.appURL
            ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari")
        guard let appURL else { return }
        NSWorkspace.shared.open(
            [url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
    }

    // MARK: Correction

    /// Re-opens a recent link in another browser and records that the first choice was wrong.
    func reopen(_ link: RecentLink, in target: BrowserTarget) {
        let correction = Router.route(link.key, sourceApp: link.sourceApp, rules: store.rules)
        open(
            link.url, key: link.key, sourceApp: link.sourceApp, in: target, kind: .corrected,
            correction)
        recent[0].explanation = "\(appName(target.bundleID)) — corrected"
        refreshSuggestions()
    }

    /// The global hotkey: with two browsers, flip to the other; otherwise ask.
    func correctLastLink() {
        guard let last = recent.first else { return NSSound.beep() }
        let others = visibleBrowsers.filter { $0.target != last.target }
        if others.count == 1 { return reopen(last, in: others[0].target) }
        picker.show(
            link: last.key.description, source: "re-open in…", choices: others, rememberLabel: nil
        ) { [weak self] choice, _ in
            if let choice { self?.reopen(last, in: choice.target) }
        }
    }

    private func registerHotKey() {
        hotKey.register(preferences.hotKey) { [weak self] in self?.correctLastLink() }
    }

    // MARK: Rules and suggestions

    func reloadRules() {
        store.reload()
        lastError = store.lastError.map {
            "rules.json is invalid, still using the last good rules: \($0)"
        }
        refreshSuggestions()
    }

    func saveRules(_ rules: [Rule]) {
        perform { try store.save(rules) }
        refreshSuggestions()
    }

    func addRule(_ rule: Rule) {
        perform { try store.add(rule) }
        refreshSuggestions()
    }

    func accept(_ suggestion: Suggestion, as rule: Rule? = nil) {
        addRule(rule ?? suggestion.makeRule())
        importedSuggestions.removeAll { $0 == suggestion }
    }

    func reject(_ suggestion: Suggestion) {
        perform { try store.reject(suggestion.shape) }
        importedSuggestions.removeAll { $0 == suggestion }
        refreshSuggestions()
    }

    func refreshSuggestions() {
        let decisions = (try? log.readAll()) ?? []
        let rejected = store.loadRejected()
        suggestions = SuggestionEngine.suggest(
            decisions: decisions, existingRules: store.rules, rejected: rejected)
        hints = SuggestionEngine.suggest(
            decisions: decisions, existingRules: store.rules, rejected: rejected,
            config: PickerHint.config)
        disagreements = SuggestionEngine.disagreements(decisions: decisions, rules: store.rules)
        importedSuggestions.removeAll { rejected.contains($0.shape) }
    }

    private func record(_ decision: Decision) {
        perform { try log.append(decision) }
        refreshSuggestions()
    }

    private func perform(_ action: () throws -> Void) {
        do { try action() } catch { lastError = "\(error)" }
    }

    // MARK: Default browser

    func makeDefaultBrowser() {
        DefaultBrowser.makeSwitchmanDefault { [weak self] in
            self?.isDefaultBrowser = DefaultBrowser.isSwitchman
        }
    }
}
