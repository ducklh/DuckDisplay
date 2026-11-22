import SwiftUI
import UIKit
import Combine

@main
struct DuckDisplayApp: App {
    @StateObject private var workspace: WorkspaceStore
    @StateObject private var externalDisplay: ExternalDisplayMonitor
    @StateObject private var windowManager: WindowManager
    @StateObject private var pointerManager: PointerManager
    @StateObject private var mouseInput: MouseInputHandler

    init() {
        let workspace = WorkspaceStore()
        let externalDisplay = ExternalDisplayMonitor()
        let windowManager = WindowManager()
        let pointerManager = PointerManager()

        _workspace = StateObject(wrappedValue: workspace)
        _externalDisplay = StateObject(wrappedValue: externalDisplay)
        _windowManager = StateObject(wrappedValue: windowManager)
        _pointerManager = StateObject(wrappedValue: pointerManager)
        _mouseInput = StateObject(
            wrappedValue: MouseInputHandler(
                windowManager: windowManager,
                pointerManager: pointerManager
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ControlCenterView()
                .environmentObject(workspace)
                .environmentObject(externalDisplay)
                .environmentObject(windowManager)
                .environmentObject(pointerManager)
                .environmentObject(mouseInput)
                .onAppear {
                    externalDisplay.refresh()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIScreen.didConnectNotification)) { _ in
                    externalDisplay.refresh()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIScreen.didDisconnectNotification)) { _ in
                    externalDisplay.refresh()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIScreen.modeDidChangeNotification)) { _ in
                    externalDisplay.refresh()
                }
                .sceneAccessory {
                    ExternalNonInteractiveAccessory {
                        ExternalWorkspaceView()
                            .environmentObject(workspace)
                            .environmentObject(externalDisplay)
                            .environmentObject(windowManager)
                            .environmentObject(pointerManager)
                            .environmentObject(mouseInput)
                    }
                }
        }
    }
}
