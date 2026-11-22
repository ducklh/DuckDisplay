import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject private var workspace: WorkspaceStore

    var body: some View {
        NavigationStack {
            Form {
                Section("External display") {
                    Label("Connect a USB-C to HDMI / DisplayPort adapter", systemImage: "cable.connector")
                    Text("When an external display is available, iPadOS presents DuckDisplay's separate, non-interactive workspace there.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Choose external content") {
                    Picker("Panel", selection: $workspace.selectedPanel) {
                        ForEach(WorkspaceStore.Panel.allCases) { panel in
                            Text(panel.rawValue).tag(panel)
                        }
                    }
                    Toggle("Show clock", isOn: $workspace.showClock)
                }

                Section("Workspace message") {
                    TextField("Headline", text: $workspace.headline)
                    TextField("Description", text: $workspace.note, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Current selection") {
                    Label(workspace.selectedPanel.rawValue, systemImage: "rectangle.on.rectangle")
                    Text("Changes are shared with the external display while this app is active.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("DuckDisplay")
        }
    }
}
