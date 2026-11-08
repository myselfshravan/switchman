import SwiftUI
import SwitchmanCore

/// Edits one rule; also used to tweak a suggestion before accepting it.
struct RuleEditor: View {
    enum Kind: String, CaseIterable, Identifiable {
        case host = "Host"
        case hostWildcard = "Domain and subdomains"
        case urlPrefix = "URL prefix"
        case regex = "Regex"

        var id: String { rawValue }
    }

    let model: AppModel
    let onSave: (Rule) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var rule: Rule
    @State private var kind: Kind
    @State private var value: String
    @State private var source: String
    @State private var note: String

    init(model: AppModel, rule: Rule, onSave: @escaping (Rule) -> Void) {
        self.model = model
        self.onSave = onSave
        _rule = State(initialValue: rule)
        let (kind, value) = Self.split(rule.pattern)
        _kind = State(initialValue: kind)
        _value = State(initialValue: value)
        _source = State(initialValue: rule.sourceAppBundleID ?? "")
        _note = State(initialValue: rule.note ?? "")
    }

    var body: some View {
        Form {
            Picker("Match", selection: $kind) {
                ForEach(Kind.allCases) { Text($0.rawValue).tag($0) }
            }
            TextField("Pattern", text: $value, prompt: Text(placeholder))
                .font(.body.monospaced())
            if let error = pattern.validationError {
                Text(error).foregroundStyle(.red).font(.caption)
            }
            Picker("Open in", selection: $rule.action) {
                Text("Always ask").tag(RuleAction.alwaysAsk)
                ForEach(targets, id: \.self) { target in
                    Text(title(target)).tag(RuleAction.open(target))
                }
            }
            TextField("Only from app", text: $source, prompt: Text("any app (or a bundle ID)"))
            TextField("Note", text: $note)
            Toggle("Enabled", isOn: $rule.enabled)
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    rule.pattern = pattern
                    rule.sourceAppBundleID = source.isEmpty ? nil : source
                    rule.note = note.isEmpty ? nil : note
                    onSave(rule)
                    dismiss()
                }
                .disabled(pattern.validationError != nil)
            }
        }
    }

    private var pattern: SwitchmanCore.Pattern {
        switch kind {
        case .host: .host(value)
        case .hostWildcard: .hostWildcard(value)
        case .urlPrefix: .urlPrefix(value)
        case .regex: .regex(value)
        }
    }

    private var placeholder: String {
        switch kind {
        case .host: "github.com"
        case .hostWildcard: "*.atlassian.net"
        case .urlPrefix: "github.com/acme/"
        case .regex: #"^docs\.google\.com/.*authuser=1"#
        }
    }

    /// Discovered browsers, plus the rule's own target if it isn't installed right now.
    private var targets: [BrowserTarget] {
        var all = model.browsers.map(\.target)
        if case .open(let target) = rule.action, !all.contains(target) { all.append(target) }
        return all
    }

    private func title(_ target: BrowserTarget) -> String {
        model.browsers.first { $0.target == target }?.title ?? "\(RuleAction.open(target))"
    }

    private static func split(_ pattern: SwitchmanCore.Pattern) -> (Kind, String) {
        switch pattern {
        case .host(let v): (.host, v)
        case .hostWildcard(let v): (.hostWildcard, v)
        case .urlPrefix(let v): (.urlPrefix, v)
        case .regex(let v): (.regex, v)
        }
    }
}
