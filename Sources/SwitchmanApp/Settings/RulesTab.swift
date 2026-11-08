import SwiftUI
import SwitchmanCore

struct RulesTab: View {
    let model: AppModel
    @State private var editing: Rule?
    @State private var testURL = ""
    @State private var testSource = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ErrorBanner(message: model.lastError)
            Text("First match wins. Drag to reorder.").font(.callout).foregroundStyle(.secondary)
            List {
                ForEach(Array(model.store.rules.enumerated()), id: \.element.id) { index, rule in
                    row(index, rule)
                }
                .onMove { from, to in
                    var rules = model.store.rules
                    rules.move(fromOffsets: from, toOffset: to)
                    model.saveRules(rules)
                }
            }
            HStack {
                Button("Add Rule…") {
                    editing = Rule(pattern: .host(""), action: .alwaysAsk)
                }
                Spacer()
                Button("Show rules.json in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([model.store.location.rules])
                }
            }
            testBox
        }
        .sheet(item: $editing) { rule in
            RuleEditor(model: model, rule: rule) { saved in
                var rules = model.store.rules
                if let index = rules.firstIndex(where: { $0.id == saved.id }) {
                    rules[index] = saved
                    model.saveRules(rules)
                } else {
                    model.addRule(saved)
                }
            }
        }
    }

    private func row(_ index: Int, _ rule: Rule) -> some View {
        HStack {
            Text("#\(index + 1)").font(.caption.monospaced()).foregroundStyle(.secondary)
            Toggle(
                "",
                isOn: Binding(
                    get: { rule.enabled },
                    set: { enabled in
                        var rules = model.store.rules
                        rules[index].enabled = enabled
                        model.saveRules(rules)
                    })
            ).labelsHidden()
            VStack(alignment: .leading) {
                Text(rule.pattern.description).font(.body.monospaced())
                Text(describe(rule)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Edit") { editing = rule }
            Button(role: .destructive) {
                model.saveRules(model.store.rules.filter { $0.id != rule.id })
            } label: {
                Image(systemName: "trash")
            }
        }
    }

    private func describe(_ rule: Rule) -> String {
        var parts: [String] = []
        switch rule.action {
        case .open(let target):
            parts.append(
                "→ " + (model.browsers.first { $0.target == target }?.title ?? "\(rule.action)"))
        case .alwaysAsk: parts.append("→ always ask")
        }
        if let source = rule.sourceAppBundleID { parts.append("from \(model.appName(source))") }
        if rule.origin != .manual { parts.append(rule.origin.rawValue) }
        if let note = rule.note { parts.append(note) }
        return parts.joined(separator: " · ")
    }

    private var testBox: some View {
        GroupBox("Test a URL") {
            VStack(alignment: .leading) {
                HStack {
                    TextField("https://github.com/acme/repo", text: $testURL)
                    TextField("source bundle ID (optional)", text: $testSource).frame(width: 220)
                }
                Text(testResult).font(.callout.monospaced()).textSelection(.enabled)
            }
        }
    }

    private var testResult: String {
        guard !testURL.isEmpty else { return " " }
        guard let key = URLKey(testURL, suffixes: .bundled) else { return "not an http(s) URL" }
        let result = Router.route(
            key, sourceApp: testSource.isEmpty ? nil : testSource, rules: model.store.rules)
        return "\(key)  →  \(model.explain(result))"
    }
}
