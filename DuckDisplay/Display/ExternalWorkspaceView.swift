import SwiftUI

struct ExternalWorkspaceView: View {
    @EnvironmentObject private var externalDisplay: ExternalDisplayMonitor
    @EnvironmentObject private var windowManager: WindowManager
    @EnvironmentObject private var pointerManager: PointerManager
    @EnvironmentObject private var mouseInput: MouseInputHandler

    var body: some View {
        DesktopCanvas()
            .preferredColorScheme(.dark)
            .allowsHitTesting(false)
            .onAppear {
                externalDisplay.setWorkspaceVisible(true)
            }
            .onDisappear {
                mouseInput.cancel(in: windowManager.desktopBounds)
                pointerManager.hide()
                externalDisplay.setWorkspaceVisible(false)
            }
    }
}
