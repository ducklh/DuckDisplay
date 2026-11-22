import SwiftUI

@main
struct DuckDisplayApp: App {
    @StateObject private var workspace = WorkspaceStore()

    var body: some Scene {
        WindowGroup {
            ControlCenterView()
                .environmentObject(workspace)
                .sceneAccessory {
                    ExternalNonInteractiveAccessory {
                        ExternalWorkspaceView()
                            .environmentObject(workspace)
                    }
                }
        }
    }
}
