import CoreGraphics
import Foundation
import XCTest
@testable import DuckDisplay

final class PointerCoordinateMapperTests: XCTestCase {
    func testConvertsBetweenOffsetCoordinateSpaces() {
        let result = PointerCoordinateMapper.convert(
            CGPoint(x: 60, y: 45),
            from: CGRect(x: 10, y: 5, width: 100, height: 80),
            to: CGRect(x: 20, y: 30, width: 400, height: 240)
        )

        XCTAssertEqual(result, CGPoint(x: 220, y: 150))
    }

    func testRejectsInvalidCoordinateSpacesAndPoints() {
        XCTAssertNil(
            PointerCoordinateMapper.convert(
                CGPoint(x: .infinity, y: 2),
                from: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)),
                to: CGRect(origin: .zero, size: CGSize(width: 20, height: 20))
            )
        )
        XCTAssertNil(
            PointerCoordinateMapper.convert(
                CGPoint.zero,
                from: CGRect(origin: .zero, size: CGSize(width: 0, height: 10)),
                to: CGRect(origin: .zero, size: CGSize(width: 20, height: 20))
            )
        )
    }
}

@MainActor
final class PointerInteractionTests: XCTestCase {
    private let bounds = CGSize(width: 1000, height: 800)

    func testHitTestingSkipsMinimizedTopWindow() {
        let back = makeWindow(zIndex: 1)
        var front = makeWindow(zIndex: 2)

        XCTAssertEqual(WindowHitTesting.window(at: CGPoint(x: 50, y: 50), in: [back, front])?.id, front.id)

        front.isMinimized = true

        XCTAssertEqual(WindowHitTesting.window(at: CGPoint(x: 50, y: 50), in: [back, front])?.id, back.id)
    }

    func testClickFocusesTheWindowUnderPointer() {
        let manager = WindowManager()
        manager.open(.dashboard, in: bounds)
        manager.open(.notes, in: bounds)
        let target = manager.windows[0]
        let controller = WindowInteractionController(windowManager: manager)
        let point = CGPoint(x: target.position.x + 120, y: target.position.y + 100)

        controller.begin(at: point)
        controller.end(at: point, in: bounds)

        XCTAssertTrue(manager.windows.first(where: { $0.id == target.id })?.isFocused == true)
    }

    func testTitleBarDragMovesWindowWithinBounds() {
        let manager = WindowManager()
        manager.open(.dashboard, in: bounds)
        let target = manager.windows[0]
        let controller = WindowInteractionController(windowManager: manager)
        let start = CGPoint(x: target.position.x + 100, y: target.position.y + 20)
        let end = CGPoint(x: start.x + 50, y: start.y + 40)

        controller.begin(at: start)
        controller.move(to: end, in: bounds)
        controller.end(at: end, in: bounds)

        let moved = manager.windows[0]
        XCTAssertEqual(moved.position, CGPoint(x: target.position.x + 50, y: target.position.y + 40))
    }

    func testResizeHandleResizesWindow() {
        let manager = WindowManager()
        manager.open(.dashboard, in: bounds)
        let target = manager.windows[0]
        let controller = WindowInteractionController(windowManager: manager)
        let start = CGPoint(x: target.position.x + target.size.width - 10, y: target.position.y + target.size.height - 10)
        let end = CGPoint(x: start.x + 100, y: start.y + 80)

        controller.begin(at: start)
        controller.move(to: end, in: bounds)
        controller.end(at: end, in: bounds)

        XCTAssertEqual(manager.windows[0].size, CGSize(width: target.size.width + 100, height: target.size.height + 80))
    }

    func testInvalidGeometryIsIgnored() {
        let manager = WindowManager()
        manager.open(.dashboard, in: bounds)
        let original = manager.windows[0]

        manager.move(original.id, to: CGPoint(x: .infinity, y: 10), in: bounds)
        manager.resize(original.id, to: CGSize(width: .nan, height: 300), in: bounds)

        XCTAssertEqual(manager.windows[0].position, original.position)
        XCTAssertEqual(manager.windows[0].size, original.size)
    }

    func testDisplayBoundsChangesClampWindowGeometry() {
        let manager = WindowManager()
        manager.open(.dashboard, in: bounds)
        manager.updateDesktopBounds(CGSize(width: 500, height: 400))

        let window = manager.windows[0]
        XCTAssertLessThanOrEqual(window.position.x + window.size.width, 500)
        XCTAssertLessThanOrEqual(window.position.y + window.size.height, 400)
    }

    func testEscapeCancellationRestoresDragOrigin() {
        let manager = WindowManager()
        manager.open(.dashboard, in: bounds)
        let original = manager.windows[0]
        let controller = WindowInteractionController(windowManager: manager)
        let start = CGPoint(x: original.position.x + 100, y: original.position.y + 20)

        controller.begin(at: start)
        controller.move(to: CGPoint(x: start.x + 80, y: start.y + 50), in: bounds)
        controller.cancel(in: bounds)

        XCTAssertEqual(manager.windows[0].position, original.position)
        XCTAssertFalse(controller.isOperating)
    }

    func testDoubleClickTitleBarMaximizesAndRestores() {
        let manager = WindowManager()
        manager.open(.dashboard, in: bounds)
        let controller = WindowInteractionController(windowManager: manager)
        let clickTime = Date(timeIntervalSince1970: 100)

        for time in [clickTime, clickTime.addingTimeInterval(0.2)] {
            let point = CGPoint(x: 100, y: 40)
            controller.begin(at: point)
            controller.end(at: point, in: bounds, time: time)
        }
        XCTAssertTrue(manager.windows[0].isMaximized)

        for time in [clickTime.addingTimeInterval(1), clickTime.addingTimeInterval(1.2)] {
            let point = CGPoint(x: 100, y: 40)
            controller.begin(at: point)
            controller.end(at: point, in: bounds, time: time)
        }
        XCTAssertFalse(manager.windows[0].isMaximized)
    }

    func testPointerCanResumeAfterExternalSceneVisibilityChanges() {
        let pointer = PointerManager()
        let monitor = ExternalDisplayMonitor()
        let manager = WindowManager()
        manager.open(.dashboard, in: bounds)

        pointer.move(to: CGPoint(x: 100, y: 120), in: bounds)
        monitor.setWorkspaceVisible(false)
        pointer.hide()
        monitor.setWorkspaceVisible(true)
        pointer.move(to: CGPoint(x: 200, y: 240), in: bounds)

        XCTAssertTrue(monitor.workspaceIsVisible)
        XCTAssertTrue(pointer.isVisible)
        XCTAssertEqual(pointer.position, CGPoint(x: 200, y: 240))
        XCTAssertEqual(manager.windows.count, 1)
    }

    private func makeWindow(zIndex: Int) -> WindowModel {
        WindowModel(
            id: UUID(),
            applicationID: WorkspaceApplication.dashboard.id,
            title: "Dashboard",
            position: CGPoint(x: 20, y: 20),
            size: CGSize(width: 300, height: 200),
            minimumSize: CGSize(width: 200, height: 150),
            zIndex: zIndex,
            isMinimized: false,
            isMaximized: false,
            isFocused: false,
            previousFrame: nil
        )
    }
}
