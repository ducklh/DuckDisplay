import Combine
import CoreGraphics
import Foundation

enum PointerVisualState: Equatable {
    case hidden
    case hovering
    case pressed
    case dragging
    case resizing
}

@MainActor
final class PointerManager: ObservableObject {
    @Published private(set) var position = CGPoint.zero
    @Published private(set) var visualState: PointerVisualState = .hidden

    var isVisible: Bool { visualState != .hidden }

    func move(to point: CGPoint, in bounds: CGSize) {
        guard point.x.isFinite, point.y.isFinite,
              bounds.width.isFinite, bounds.height.isFinite,
              bounds.width > 0, bounds.height > 0 else { return }

        position = CGPoint(
            x: min(max(0, point.x), bounds.width),
            y: min(max(0, point.y), bounds.height)
        )
        if visualState == .hidden {
            visualState = .hovering
        }
    }

    func setVisualState(_ state: PointerVisualState) {
        visualState = state
    }

    func hide() {
        visualState = .hidden
    }
}

enum PointerCoordinateMapper {
    static func convert(_ point: CGPoint, from source: CGRect, to destination: CGRect) -> CGPoint? {
        guard point.x.isFinite, point.y.isFinite,
              source.origin.x.isFinite, source.origin.y.isFinite,
              destination.origin.x.isFinite, destination.origin.y.isFinite,
              source.width.isFinite, source.height.isFinite,
              destination.width.isFinite, destination.height.isFinite,
              source.width > 0, source.height > 0,
              destination.width > 0, destination.height > 0 else {
            return nil
        }

        let x = destination.minX + (point.x - source.minX) * destination.width / source.width
        let y = destination.minY + (point.y - source.minY) * destination.height / source.height
        guard x.isFinite, y.isFinite else { return nil }
        return CGPoint(x: x, y: y)
    }
}

enum WindowHitTesting {
    static func window(at point: CGPoint, in windows: [WindowModel]) -> WindowModel? {
        guard point.x.isFinite, point.y.isFinite else { return nil }
        return windows
            .filter { window in
                guard !window.isMinimized,
                      window.position.x.isFinite, window.position.y.isFinite,
                      window.size.width.isFinite, window.size.height.isFinite,
                      window.size.width > 0, window.size.height > 0 else {
                    return false
                }
                return CGRect(origin: window.position, size: window.size).contains(point)
            }
            .max { $0.zIndex < $1.zIndex }
    }
}

@MainActor
final class WindowInteractionController {
    private enum Operation {
        case titleBar(UUID, startPoint: CGPoint, startPosition: CGPoint)
        case resize(UUID, startPoint: CGPoint, startSize: CGSize)
        case press(UUID, startPoint: CGPoint, isTitleBar: Bool)
    }

    private let windowManager: WindowManager
    private var operation: Operation?
    private var previousTitleBarClick: (windowID: UUID, time: Date)?

    init(windowManager: WindowManager) {
        self.windowManager = windowManager
    }

    var isOperating: Bool { operation != nil }

    var visualState: PointerVisualState? {
        switch operation {
        case .some(.titleBar(_, _, _)): .dragging
        case .some(.resize(_, _, _)): .resizing
        case .some(.press(_, _, _)): .pressed
        case .none: nil
        }
    }

    func begin(at point: CGPoint) {
        guard point.x.isFinite, point.y.isFinite,
              let window = WindowHitTesting.window(at: point, in: windowManager.visibleWindows) else {
            operation = nil
            previousTitleBarClick = nil
            return
        }

        windowManager.focus(window.id)
        let frame = CGRect(origin: window.position, size: window.size)
        let isTitleBar = point.y >= frame.minY && point.y <= frame.minY + 44
        let isResizeHandle = point.x >= frame.maxX - 40 && point.y >= frame.maxY - 40

        if !window.isMaximized, isTitleBar {
            operation = .titleBar(window.id, startPoint: point, startPosition: window.position)
        } else if !window.isMaximized, isResizeHandle {
            operation = .resize(window.id, startPoint: point, startSize: window.size)
        } else {
            operation = .press(window.id, startPoint: point, isTitleBar: isTitleBar)
        }
    }

    func move(to point: CGPoint, in bounds: CGSize) {
        guard point.x.isFinite, point.y.isFinite else { return }
        switch operation {
        case let .some(.titleBar(id, startPoint, startPosition)):
            windowManager.move(
                id,
                to: CGPoint(
                    x: startPosition.x + point.x - startPoint.x,
                    y: startPosition.y + point.y - startPoint.y
                ),
                in: bounds
            )
        case let .some(.resize(id, startPoint, startSize)):
            windowManager.resize(
                id,
                to: CGSize(
                    width: startSize.width + point.x - startPoint.x,
                    height: startSize.height + point.y - startPoint.y
                ),
                in: bounds
            )
        case .some(.press(_, _, _)), .none:
            break
        }
    }

    func end(at point: CGPoint, in bounds: CGSize, time: Date = .now) {
        guard let operation else {
            previousTitleBarClick = nil
            return
        }
        defer { self.operation = nil }

        let click: (id: UUID, startPoint: CGPoint, isTitleBar: Bool)
        switch operation {
        case let .titleBar(id, startPoint, _):
            click = (id, startPoint, true)
        case let .press(id, startPoint, isTitleBar):
            click = (id, startPoint, isTitleBar)
        case .resize(_, _, _):
            previousTitleBarClick = nil
            return
        }

        guard click.isTitleBar,
              hypot(point.x - click.startPoint.x, point.y - click.startPoint.y) < 4 else {
            previousTitleBarClick = nil
            return
        }

        let clickInterval = previousTitleBarClick.map { time.timeIntervalSince($0.time) }
        if let previous = previousTitleBarClick,
           previous.windowID == click.id,
           let clickInterval,
           clickInterval >= 0,
           clickInterval <= 0.4 {
            windowManager.toggleMaximize(click.id, in: bounds)
            previousTitleBarClick = nil
        } else {
            previousTitleBarClick = (click.id, time)
        }
    }

    func cancel(in bounds: CGSize) {
        guard let operation else { return }
        switch operation {
        case let .titleBar(id, _, startPosition):
            windowManager.move(id, to: startPosition, in: bounds)
        case let .resize(id, _, startSize):
            windowManager.resize(id, to: startSize, in: bounds)
        case .press(_, _, _):
            break
        }
        self.operation = nil
        previousTitleBarClick = nil
    }

    func focus(_ id: UUID) {
        windowManager.focus(id)
    }

    func toggleMaximize(_ id: UUID, in bounds: CGSize) {
        windowManager.toggleMaximize(id, in: bounds)
    }

    func minimize(_ id: UUID) {
        windowManager.minimize(id)
    }

    func close(_ id: UUID) {
        windowManager.close(id)
    }
}

@MainActor
final class MouseInputHandler: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    let pointerManager: PointerManager
    let interactionController: WindowInteractionController

    init(windowManager: WindowManager, pointerManager: PointerManager) {
        self.pointerManager = pointerManager
        interactionController = WindowInteractionController(windowManager: windowManager)
    }

    var isOperating: Bool { interactionController.isOperating }

    func movePointer(
        to point: CGPoint,
        from sourceSize: CGSize,
        in workspaceBounds: CGSize
    ) {
        guard let mapped = PointerCoordinateMapper.convert(
            point,
            from: CGRect(origin: .zero, size: sourceSize),
            to: CGRect(origin: .zero, size: workspaceBounds)
        ) else { return }

        pointerManager.move(to: mapped, in: workspaceBounds)
        if interactionController.isOperating {
            interactionController.move(to: mapped, in: workspaceBounds)
        } else {
            pointerManager.setVisualState(.hovering)
        }
    }

    func beginPress(
        at point: CGPoint,
        from sourceSize: CGSize,
        in workspaceBounds: CGSize
    ) {
        guard let mapped = PointerCoordinateMapper.convert(
            point,
            from: CGRect(origin: .zero, size: sourceSize),
            to: CGRect(origin: .zero, size: workspaceBounds)
        ) else { return }

        pointerManager.move(to: mapped, in: workspaceBounds)
        interactionController.begin(at: mapped)
        pointerManager.setVisualState(interactionController.visualState ?? .pressed)
    }

    func endPress(
        at point: CGPoint,
        from sourceSize: CGSize,
        in workspaceBounds: CGSize,
        time: Date = .now
    ) {
        guard let mapped = PointerCoordinateMapper.convert(
            point,
            from: CGRect(origin: .zero, size: sourceSize),
            to: CGRect(origin: .zero, size: workspaceBounds)
        ) else {
            interactionController.cancel(in: workspaceBounds)
            pointerManager.setVisualState(.hovering)
            return
        }

        pointerManager.move(to: mapped, in: workspaceBounds)
        interactionController.end(at: mapped, in: workspaceBounds, time: time)
        pointerManager.setVisualState(.hovering)
    }

    func cancel(in workspaceBounds: CGSize) {
        interactionController.cancel(in: workspaceBounds)
        pointerManager.setVisualState(.hovering)
    }

    func pointerExited() {
        guard !interactionController.isOperating else { return }
        pointerManager.hide()
    }
}
