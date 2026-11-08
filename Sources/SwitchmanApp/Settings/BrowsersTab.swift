import SwiftUI
import SwitchmanCore

struct BrowsersTab: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shown in the picker in this order (numbers 1–9). Drag to reorder.")
                .font(.callout).foregroundStyle(.secondary)
            List {
                ForEach(model.preferences.arrange(model.browsers)) { choice in
                    HStack {
                        Image(nsImage: choice.icon).resizable().frame(width: 20, height: 20)
                        Toggle(choice.title, isOn: visible(choice.target))
                    }
                }
                .onMove { from, to in
                    var order = model.preferences.arrange(model.browsers).map(\.target)
                    order.move(fromOffsets: from, toOffset: to)
                    model.preferences.order = order
                }
            }
            Picker("If anything goes wrong, open in", selection: $model.preferences.fallback) {
                Text("Safari").tag(BrowserTarget?.none)
                ForEach(model.browsers) { Text($0.title).tag(Optional($0.target)) }
            }
            Text(
                "Chromium profiles open via --profile-directory, so a link lands in the right "
                    + "profile even when the browser is already running."
            )
            .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func visible(_ target: BrowserTarget) -> Binding<Bool> {
        Binding(
            get: { !model.preferences.hidden.contains(target) },
            set: { shown in
                if shown {
                    model.preferences.hidden.remove(target)
                } else {
                    model.preferences.hidden.insert(target)
                }
            })
    }
}
