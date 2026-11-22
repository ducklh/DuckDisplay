import SwiftUI
import UIKit
import Combine

@main
struct DuckDisplayApp: App {
    @StateObject private var workspace = WorkspaceStore()
    @StateObject private var externalDisplay = ExternalDisplayMonitor()
    @StateObject private var windowManager = WindowManager()

    var body: some Scene {
        WindowGroup {
            ControlCenterView()
                .environmentObject(workspace)
                .environmentObject(externalDisplay)
                .environmentObject(windowManager)
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
                    }
                }
        }
    }
}
