import SwiftUI
import SwitchmanCore

struct SuggestionsTab: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Learned from your choices. Nothing changes until you accept.")
                .font(.callout).foregroundStyle(.secondary)
            List {
                if !model.disagreements.isEmpty {
                    Section("Rules you keep correcting") {
                        ForEach(model.disagreements, id: \.ruleIndex) { d in
                            DisagreementRow(model: model, disagreement: d)
                        }
                    }
                }
                Section("Suggestions") {
                    if model.suggestions.isEmpty {
                        Text("No suggestions yet — keep picking, or import your history.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.suggestions, id: \.self) {
                        SuggestionRow(model: model, suggestion: $0)
                    }
                }
            }
        }
        .onAppear { model.refreshSuggestions() }
    }
}

struct SuggestionRow: View {
    let model: AppModel
    let suggestion: Suggestion
    @State private var editing: Rule?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.makeRule().summary).font(.body.monospaced())
                Text(stats).font(.caption).foregroundStyle(.secondary)
                Text(suggestion.examples.map(\.description).joined(separator: "  ·  "))
                    .font(.caption.monospaced()).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Button("Accept") { model.accept(suggestion) }.buttonStyle(.borderedProminent)
            Button("Edit…") { editing = suggestion.makeRule() }
            Button("Reject") { model.reject(suggestion) }
        }
        .sheet(item: $editing) { rule in
            RuleEditor(model: model, rule: rule) { model.accept(suggestion, as: $0) }
        }
    }

    private var stats: String {
        let percent = Int((suggestion.confidence * 100).rounded())
        let origin = suggestion.origin == .imported ? " · from browser history" : ""
        return "support \(String(format: "%g", suggestion.support)) · \(percent)% agree\(origin)"
    }
}

struct DisagreementRow: View {
    let model: AppModel
    let disagreement: Disagreement

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(disagreement.summary)
                Text("you re-opened in \(model.appName(disagreement.chosen.bundleID))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Switch rule to \(model.appName(disagreement.chosen.bundleID))") {
                var rules = model.store.rules
                guard let index = rules.firstIndex(where: { $0.id == disagreement.rule.id }) else {
                    return
                }
                rules[index].action = .open(disagreement.chosen)
                model.saveRules(rules)
            }
            Button("Delete Rule") {
                model.saveRules(model.store.rules.filter { $0.id != disagreement.rule.id })
            }
        }
    }
}
