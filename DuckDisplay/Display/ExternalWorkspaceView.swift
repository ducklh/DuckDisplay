import SwiftUI

struct ExternalWorkspaceView: View {
    @EnvironmentObject private var externalDisplay: ExternalDisplayMonitor

    var body: some View {
        DesktopCanvas()
            .preferredColorScheme(.dark)
            .allowsHitTesting(false)
            .onAppear {
                externalDisplay.setWorkspaceVisible(true)
            }
            .onDisappear {
                externalDisplay.setWorkspaceVisible(false)
            }
    }
}
