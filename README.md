# DuckDisplay (non-jailbreak external-display workspace)

A SwiftUI iPad app for iPadOS 27 that presents an app-owned desktop workspace on a connected external display using Apple's public `ExternalNonInteractiveAccessory` / `UISceneAccessory.externalNonInteractive` API. UIKit screen notifications provide connection, disconnection, and display-mode diagnostics; iPadOS owns presentation and lifecycle of the external scene.

## Architecture review and implementation

- `DuckDisplayApp`, `ExternalDisplayMonitor`, `ControlCenterView`, `ExternalWorkspaceView`, and the shared `WorkspaceStore` remain the app and display lifecycle foundation.
- `WindowManager` is the single source of window state shared between the iPad control surface and the external workspace. `WindowModel` records the app ID, title, frame, minimum size, z-index, minimized/maximized/focused flags, and saved frame for restore.
- `DesktopCanvas`, `AppWindow`, `WindowTitleBar`, `DockView`, and `AppLauncher` render the desktop-style workspace. The sample Dashboard, Browser, Notes, and Terminal surfaces are app-owned examples, not separate system applications.
- The iPad's Control Center can open, focus, minimize, restore, maximize, close, move, and resize windows. The optional virtual-pointer pad receives SwiftUI hover and drag gestures only while the physical pointer is over that iPad app view, then draws a mapped pointer on the passive external workspace. It is not a system pointer and cannot track the pointer while it is over HDMI.
- External workspace content continues to have hit testing disabled. The `ExternalNonInteractiveAccessory` scene does not provide guaranteed mouse, touch, or keyboard input; native cursor movement, clicks, and cross-display pointer transfer are not supported or claimed.
- Window placement and sizing use the accessory scene's current SwiftUI geometry, not `UIScreen` pixel metadata. Windows are clamped to the desktop and resized to fit when scene bounds change.
- Display connection/mode diagnostics and the shared workspace message/clock controls are retained.

## Important limitations

This is **app-level extended content**, not a system-wide extended iPad desktop or a general-purpose host for other apps.

- It cannot move Safari, Telegram, Settings, or other third-party iPad apps onto the monitor.
- `ExternalNonInteractiveAccessory` does not provide an interactive external window manager. The virtual-pointer pad is an app-drawn, best-effort control mapped from pointer events inside the iPad app; it cannot receive movement or clicks while the mouse is over HDMI, or forward the native system cursor to that display.
- SwiftUI `onContinuousHover` and drag gestures are used on the primary app scene. Their behavior with a USB mouse/trackpad must still be verified on the target iPad; no global or cross-scene input capture is used.
- It does not unlock Stage Manager external-display support on A14.
- It does not require jailbreak, private APIs, a Mac host, or a network connection.
- Actual availability and behavior must be tested on the target iPadOS 27 build and a wired display.

## Requirements

- Xcode with the iPadOS 27 SDK.
- iPad Gen 10 (A14) running iPadOS 27 or later.
- USB-C to HDMI or DisplayPort adapter/cable.
- Apple Developer signing or a development signing team for device installation.

## Generate the Xcode project

Use XcodeGen if you need to regenerate the checked-in Xcode project. Run these commands from the repository root (the `project.yml` file is here):

```bash
brew install xcodegen
xcodegen generate
```

Open `DuckDisplay.xcodeproj` in Xcode 27 or later, select the DuckDisplay target, set your Development Team under Signing & Capabilities, select the connected iPad Gen 10, and Build & Run. The target is iPad-only. For an unsigned device-independent build check:

```bash
xcodebuild -project DuckDisplay.xcodeproj -scheme DuckDisplay \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

To install on iPad, use Xcode's Run action with the device selected and a valid Development Team. A connected-device deployment cannot be verified from a Linux host. The build command above also requires Xcode and its iPadOS SDK.

## Device test checklist

Run on an iPad Gen 10 with a USB-C HDMI/DisplayPort adapter and a physical monitor; the simulator cannot verify this display lifecycle or external accessory input limitations.

1. **iPad-only behavior:** Build and install on iPad Gen 10; verify the app target is not offered for iPhone.
2. **No display at launch:** Open DuckDisplay with HDMI disconnected. Confirm the iPad Control Center and window controls remain usable and no external display is reported.
3. **Connect and initial window:** Connect HDMI while the app is foregrounded. Confirm display bounds/mode are reported and iPadOS presents the accessory with its initial Dashboard window.
4. **Multiple windows:** Open multiple instances and different app surfaces from the iPad control surface. Confirm every window has a unique entry and the external workspace shows each visible window.
5. **Virtual pointer (iPad only):** Connect a USB mouse. Move it inside the Control Center's virtual-pointer pad and confirm the app-drawn pointer appears over the HDMI workspace. Move the physical pointer outside the pad and onto HDMI; DuckDisplay must not claim to follow it there or show a system pointer it does not own.
6. **Window interaction:** With the mouse over the iPad pad, click a window to focus, drag a title bar to move, use the lower-right corner to resize, and double-click the title bar to maximize/restore. Verify Escape cancels an active drag and right-click opens the pad's window context menu. Confirm external workspace hit testing remains disabled.
7. **Mouse buttons and scrolling:** On the iPad, check USB mouse click, double-click, right-click, and scroll wheel. On HDMI, confirm native clicks and scrolling do not control the app. Scrolling over the virtual pad is not forwarded to the external workspace.
8. **Keyboard:** Check Escape cancellation and hardware keyboard input on the iPad. Keyboard input on HDMI is not supported.
9. **Resize and minimum size:** Use iPad Make larger/smaller actions. Confirm minimum sizing and desktop bounds are enforced.
10. **Minimize and restore:** Minimize a window from the iPad and restore it from the dock or the iPad window list.
11. **Focus and z-order:** Focus windows in different orders from the iPad and confirm the selected window renders in front.
12. **Maximize and restore size:** Maximize a window, restore it, and confirm its prior frame returns (clamped if the display bounds changed).
13. **Close:** Close the focused and non-focused windows. Confirm closed windows are removed and do not reappear after reconnect.
14. **Resolution/orientation:** Rotate the iPad or switch the monitor between supported modes/resolutions. Confirm windows stay within the new scene bounds and maximized windows follow the new size.
15. **Disconnect/reconnect:** Unplug and reconnect HDMI. Confirm the iPad remains responsive, window state remains managed, and no display/window status is falsely shown as active.
16. **Unsupported configuration:** Try an unsupported adapter/mode. Confirm Control Center remains usable and does not claim that a workspace is active when iPadOS has not presented it.

## Project structure

```text
DuckDisplay/
├── App/DuckDisplayApp.swift
├── Core/WorkspaceStore.swift
├── Core/WindowModel.swift
├── Core/WindowManager.swift
├── Core/PointerInteraction.swift
├── Display/DesktopCanvas.swift
├── Display/AppWindow.swift
├── Display/WindowTitleBar.swift
├── Display/DockView.swift
├── Display/AppLauncher.swift
├── Display/ExternalDisplayMonitor.swift
├── Display/ExternalWorkspaceView.swift
└── UI/
    ├── ControlCenterView.swift
    └── VirtualPointerPad.swift
```

## Build verification

The project targets iPadOS 27 and Swift 6. Build it with Xcode 27 or later and the iPadOS 27 SDK using the command above. Verify deployment and the device checklist on a physical iPad Gen 10. The external display path is not testable on a Linux development environment or the iOS simulator.
