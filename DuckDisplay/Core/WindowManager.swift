import Combine
import CoreGraphics
import Foundation

@MainActor
final class WindowManager: ObservableObject {
    @Published private(set) var windows: [WindowModel] = []
    @Published private(set) var desktopBounds = CGSize(width: 1280, height: 720)

    private var nextZIndex = 0
    private var hasCreatedInitialWindow = false

    var visibleWindows: [WindowModel] {
        windows
            .filter { !$0.isMinimized }
            .sorted { $0.zIndex < $1.zIndex }
    }

    var minimizedWindows: [WindowModel] {
        windows.filter(\.isMinimized).sorted { $0.zIndex > $1.zIndex }
    }

    func open(_ application: WorkspaceApplication, in bounds: CGSize) {
        guard hasValidBounds(bounds) else { return }

        hasCreatedInitialWindow = true
        let size = fittedSize(application.defaultSize, minimum: application.minimumSize, in: bounds)
        let offset = CGFloat(windows.count % 7) * 28
        let position = clampedPosition(
            CGPoint(x: 36 + offset, y: 36 + offset),
            size: size,
            in: bounds
        )
        focusExistingWindowIfNeeded()
        nextZIndex += 1
        windows.append(
            WindowModel(
                id: UUID(),
                applicationID: application.id,
                title: application.title,
                position: position,
                size: size,
                minimumSize: application.minimumSize,
                zIndex: nextZIndex,
                isMinimized: false,
                isMaximized: false,
                isFocused: true,
                previousFrame: nil
            )
        )
    }

    func openInitialWindowIfNeeded(in bounds: CGSize) {
        guard !hasCreatedInitialWindow else { return }
        open(.dashboard, in: bounds)
    }

    func focus(_ id: UUID) {
        guard let index = windows.firstIndex(where: { $0.id == id }), !windows[index].isMinimized else {
            return
        }
        nextZIndex += 1
        for windowIndex in windows.indices {
            windows[windowIndex].isFocused = windowIndex == index
        }
        windows[index].zIndex = nextZIndex
    }

    func close(_ id: UUID) {
        windows.removeAll { $0.id == id }
        focusTopmostWindow()
    }

    func minimize(_ id: UUID) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].isMinimized = true
        windows[index].isFocused = false
        focusTopmostWindow()
    }

    func restore(_ id: UUID) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].isMinimized = false
        focus(id)
    }

    func toggleMaximize(_ id: UUID, in bounds: CGSize) {
        guard let index = windows.firstIndex(where: { $0.id == id }),
              hasValidBounds(bounds) else { return }

        if windows[index].isMaximized {
            if let frame = windows[index].previousFrame {
                let size = fittedSize(
                    frame.size,
                    minimum: windows[index].minimumSize,
                    in: bounds
                )
                windows[index].size = size
                windows[index].position = clampedPosition(frame.origin, size: size, in: bounds)
            }
            windows[index].previousFrame = nil
            windows[index].isMaximized = false
        } else {
            windows[index].previousFrame = CGRect(origin: windows[index].position, size: windows[index].size)
            windows[index].position = .zero
            windows[index].size = bounds
            windows[index].isMaximized = true
        }
        focus(id)
    }

    func move(_ id: UUID, to position: CGPoint, in bounds: CGSize) {
        guard let index = windows.firstIndex(where: { $0.id == id }),
              !windows[index].isMaximized,
              hasValidBounds(bounds),
              position.x.isFinite,
              position.y.isFinite else { return }
        windows[index].position = clampedPosition(position, size: windows[index].size, in: bounds)
    }

    func resize(_ id: UUID, to size: CGSize, in bounds: CGSize) {
        guard let index = windows.firstIndex(where: { $0.id == id }),
              !windows[index].isMaximized,
              hasValidBounds(bounds),
              size.width.isFinite,
              size.height.isFinite else { return }
        let fitted = fittedSize(size, minimum: windows[index].minimumSize, in: bounds)
        windows[index].size = fitted
        windows[index].position = clampedPosition(windows[index].position, size: fitted, in: bounds)
    }

    func moveBy(_ id: UUID, dx: CGFloat, dy: CGFloat, in bounds: CGSize) {
        guard let window = windows.first(where: { $0.id == id }) else { return }
        move(
            id,
            to: CGPoint(x: window.position.x + dx, y: window.position.y + dy),
            in: bounds
        )
    }

    func resizeBy(_ id: UUID, dw: CGFloat, dh: CGFloat, in bounds: CGSize) {
        guard let window = windows.first(where: { $0.id == id }) else { return }
        resize(
            id,
            to: CGSize(width: window.size.width + dw, height: window.size.height + dh),
            in: bounds
        )
    }

    func updateDesktopBounds(_ bounds: CGSize) {
        guard hasValidBounds(bounds) else { return }
        desktopBounds = bounds
        for index in windows.indices {
            if windows[index].isMaximized {
                windows[index].position = .zero
                windows[index].size = bounds
                continue
            }
            let size = fittedSize(
                windows[index].size,
                minimum: windows[index].minimumSize,
                in: bounds
            )
            windows[index].size = size
            windows[index].position = clampedPosition(
                windows[index].position,
                size: size,
                in: bounds
            )
            if let previous = windows[index].previousFrame {
                let previousSize = fittedSize(
                    previous.size,
                    minimum: windows[index].minimumSize,
                    in: bounds
                )
                windows[index].previousFrame = CGRect(
                    origin: clampedPosition(previous.origin, size: previousSize, in: bounds),
                    size: previousSize
                )
            }
        }
    }

    private func clampedPosition(_ position: CGPoint, size: CGSize, in bounds: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(0, position.x), max(0, bounds.width - size.width)),
            y: min(max(0, position.y), max(0, bounds.height - size.height))
        )
    }

    private func fittedSize(_ requested: CGSize, minimum: CGSize, in bounds: CGSize) -> CGSize {
        return CGSize(
            width: min(max(minimum.width, requested.width), bounds.width),
            height: min(max(minimum.height, requested.height), bounds.height)
        )
    }

    private func hasValidBounds(_ bounds: CGSize) -> Bool {
        bounds.width.isFinite && bounds.height.isFinite &&
            bounds.width > 0 && bounds.height > 0
    }

    private func focusExistingWindowIfNeeded() {
        for index in windows.indices {
            windows[index].isFocused = false
        }
    }

    private func focusTopmostWindow() {
        guard let topmost = windows.indices
            .filter({ !windows[$0].isMinimized })
            .max(by: { windows[$0].zIndex < windows[$1].zIndex }) else {
            return
        }
        nextZIndex += 1
        windows[topmost].zIndex = nextZIndex
        for index in windows.indices {
            windows[index].isFocused = index == topmost
        }
    }
}
