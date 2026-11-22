import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject private var workspace: WorkspaceStore
    @EnvironmentObject private var externalDisplay: ExternalDisplayMonitor
    @EnvironmentObject private var windowManager: WindowManager

    var body: some View {
        NavigationStack {
            Form {
                Section("External display") {
                    Label("Connect a USB-C to HDMI / DisplayPort adapter", systemImage: "cable.connector")
                    Text("When an external display is available, iPadOS presents DuckDisplay's separate, non-interactive workspace there.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let display = externalDisplay.display {
                        Label(
                            externalDisplay.workspaceIsVisible ? "Workspace active" : "Display detected",
                            systemImage: "checkmark.circle.fill"
                        )
                        Text("Display bounds: \(display.boundsDescription)")
                        Text("Current video mode: \(display.currentModeDescription)")
                        Text("Native resolution: \(display.nativeBoundsDescription) · scale \(display.scale, specifier: "%.2g") (native \(display.nativeScale, specifier: "%.2g"))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Available display modes: \(display.availableModeCount)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("No external display detected", systemImage: "display")
                        Text("Display detection and external scene presentation are managed by iPadOS. Unsupported adapters or display configurations may not provide an external workspace.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Choose external content") {
                    Picker("Panel", selection: $workspace.selectedPanel) {
                        ForEach(WorkspaceStore.Panel.allCases) { panel in
                            Text(panel.rawValue).tag(panel)
                        }
                    }
                    Toggle("Show clock", isOn: $workspace.showClock)
                    Button {
                        windowManager.open(application(for: workspace.selectedPanel), in: windowManager.desktopBounds)
                    } label: {
                        Label("Open \(workspace.selectedPanel.rawValue) window", systemImage: "plus.rectangle.on.rectangle")
                    }
                }

                Section("Applications") {
                    ForEach(WorkspaceApplication.allCases) { application in
                        Button {
                            windowManager.open(application, in: windowManager.desktopBounds)
                        } label: {
                            Label("Open \(application.title)", systemImage: application.symbol)
                        }
                    }
                }

                Section("Windows (\(windowManager.windows.count))") {
                    if windowManager.windows.isEmpty {
                        Text("Open an app to create its first window.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(windowManager.windows) { window in
                        HStack(spacing: 10) {
                            Button {
                                windowManager.restore(window.id)
                                windowManager.focus(window.id)
                            } label: {
                                Label(window.title, systemImage: WorkspaceApplication(id: window.applicationID)?.symbol ?? "app")
                                    .foregroundStyle(window.isFocused ? Color.accentColor : Color.primary)
                            }
                            .buttonStyle(.plain)

                            Spacer(minLength: 4)
                            Text(window.isMinimized ? "Minimized" : window.isMaximized ? "Maximized" : "Open")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Menu {
                                Button("Focus", systemImage: "scope") {
                                    windowManager.restore(window.id)
                                    windowManager.focus(window.id)
                                }
                                if window.isMinimized {
                                    Button("Restore", systemImage: "arrow.up.forward.app") {
                                        windowManager.restore(window.id)
                                    }
                                } else {
                                    Button("Minimize", systemImage: "minus.rectangle") {
                                        windowManager.minimize(window.id)
                                    }
                                    Button(window.isMaximized ? "Restore Size" : "Maximize", systemImage: "arrow.up.left.and.arrow.down.right") {
                                        windowManager.toggleMaximize(window.id, in: windowManager.desktopBounds)
                                    }
                                }
                                Divider()
                                Button("Move left", systemImage: "arrow.left") {
                                    windowManager.moveBy(window.id, dx: -40, dy: 0, in: windowManager.desktopBounds)
                                }
                                Button("Move right", systemImage: "arrow.right") {
                                    windowManager.moveBy(window.id, dx: 40, dy: 0, in: windowManager.desktopBounds)
                                }
                                Button("Move up", systemImage: "arrow.up") {
                                    windowManager.moveBy(window.id, dx: 0, dy: -40, in: windowManager.desktopBounds)
                                }
                                Button("Move down", systemImage: "arrow.down") {
                                    windowManager.moveBy(window.id, dx: 0, dy: 40, in: windowManager.desktopBounds)
                                }
                                Button("Make larger", systemImage: "arrow.up.left.and.arrow.down.right") {
                                    windowManager.resizeBy(window.id, dw: 80, dh: 60, in: windowManager.desktopBounds)
                                }
                                Button("Make smaller", systemImage: "arrow.down.right.and.arrow.up.left") {
                                    windowManager.resizeBy(window.id, dw: -80, dh: -60, in: windowManager.desktopBounds)
                                }
                                Divider()
                                Button("Close", systemImage: "xmark", role: .destructive) {
                                    windowManager.close(window.id)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title3)
                            }
                            .accessibilityLabel("Actions for \(window.title)")
                        }
                    }
                    Text("The iPad control surface is interactive. The external accessory is non-interactive; window gestures there are best-effort and may not receive input.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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

    private func application(for panel: WorkspaceStore.Panel) -> WorkspaceApplication {
        switch panel {
        case .dashboard: .dashboard
        case .browser: .browser
        case .notes: .notes
        case .terminal: .terminal
        }
    }
}
