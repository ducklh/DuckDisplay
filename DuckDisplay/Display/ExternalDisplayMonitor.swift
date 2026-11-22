import UIKit
import Combine

@MainActor
final class ExternalDisplayMonitor: ObservableObject {
    struct DisplayDetails: Equatable {
        let bounds: CGSize
        let nativeBounds: CGSize
        let currentModeSize: CGSize?
        let scale: CGFloat
        let nativeScale: CGFloat
        let availableModeCount: Int

        init(screen: UIScreen) {
            bounds = screen.bounds.size
            nativeBounds = screen.nativeBounds.size
            currentModeSize = screen.currentMode?.size
            scale = screen.scale
            nativeScale = screen.nativeScale
            availableModeCount = screen.availableModes.count
        }

        var boundsDescription: String {
            "\(Int(bounds.width)) x \(Int(bounds.height)) pt"
        }

        var nativeBoundsDescription: String {
            "\(Int(nativeBounds.width)) x \(Int(nativeBounds.height)) px"
        }

        var currentModeDescription: String {
            guard let currentModeSize else { return "Unavailable" }
            return "\(Int(currentModeSize.width)) x \(Int(currentModeSize.height)) px"
        }
    }

    @Published private(set) var display: DisplayDetails?
    @Published private(set) var workspaceIsVisible = false

    func refresh() {
        let screens = UIScreen.screens
        let primaryScreen = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.session.role == .windowApplication }?.screen
            ?? screens.first

        display = screens
            .first { $0 !== primaryScreen }
            .map(DisplayDetails.init(screen:))
    }

    func setWorkspaceVisible(_ isVisible: Bool) {
        workspaceIsVisible = isVisible
    }
}
