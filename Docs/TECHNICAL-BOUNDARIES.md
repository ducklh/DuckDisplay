# Technical boundaries

## Supported path

Use Apple's public external-display accessory API:

- SwiftUI `.sceneAccessory { ExternalNonInteractiveAccessory { ... } }`
- UIKit `UISceneAccessory.externalNonInteractive(sceneConfiguration:)`
- External scene role: `windowExternalDisplayNonInteractive`

The external display is an app-owned, full-screen, non-interactive presentation surface with the `windowExternalDisplayNonInteractive` role. It can render a desktop-style arrangement of this app's own windows, but it does not receive guaranteed pointer, touch, or keyboard input. DuckDisplay must keep this scene passive and must not describe it as a native external mouse target.
UIKit's public `UIScreen.didConnectNotification`, `didDisconnectNotification`, and `modeDidChangeNotification` notifications are used only to report connected-screen details in Control Center. The accessory scene itself remains system-managed. Its SwiftUI geometry is the source of truth for workspace layout; screen bounds and mode metadata are diagnostic rather than a substitute for scene size.

## Unsupported goal on iPad Gen 10

A third-party app cannot turn the A14 iPad into a system-wide interactive extended desktop equivalent to Stage Manager on M-series iPads. That would require OS-level support from Apple. Jailbreak is not part of this project and would not guarantee the capability.

## Acceptance criteria for the PoC

- The iPad control UI remains usable.
- The HDMI display shows content different from the iPad UI.
- Changes on the iPad update the external content.
- HDMI disconnect/reconnect does not crash the app.
- Connection, disconnection, and mode changes update the reported external-screen details.
- Orientation and resolution changes relayout the external workspace using its current scene geometry.
- No jailbreak, private API, or Mac-side host is required.

## Known limitations

- iPadOS decides whether to create and present the non-interactive external scene. Detecting a connected `UIScreen` does not guarantee that the accessory scene can be presented.
- The screen list and mode notifications provide display metadata; the accessory scene may have different safe-area or point dimensions. Use the scene's `GeometryReader` for rendering.
- The accessory is non-interactive and is not an independent system application. This app cannot host native Safari, Telegram, Terminal, or other third-party system apps as separate monitor apps.
- External accessory content is rendered without hit testing. Touch, pointer, and keyboard input on the external display are unsupported; no external keyboard or mouse support is claimed.
- The optional virtual-pointer pad uses public SwiftUI `onContinuousHover` and drag gestures in the iPad app scene. It maps those in-app coordinates to a cursor rendered in the external scene. It is an app-drawn virtual pointer, not a system cursor: it can only track input while the physical mouse is over the iPad app's pad and cannot capture input globally or after the pointer moves onto HDMI.
- Window state and actions remain in the shared `WindowManager`. Escape cancels an in-progress virtual-pointer drag while the iPad pad has keyboard focus. Right-click on the pad presents its app-owned context menu.
- Window state is owned by one shared `WindowManager`; external scene geometry is used to clamp/rescale frames after display changes. `WorkspaceStore` continues to own the shared workspace content and display preferences.
- Monitor adapters, EDID negotiation, refresh rates, protected content, and available resolutions are controlled by iPadOS and the hardware. Unsupported combinations may leave the accessory unavailable.
- A14 hardware does not gain system-wide Stage Manager external-display support from this app.

## Input verification status

The public scene role and code establish that the external accessory is non-interactive and that hit testing is disabled. The primary iPad scene can use public SwiftUI hover and gesture APIs, but receipt of USB mouse events and the interaction feel must be verified on the target iPadOS build and hardware. This repository has not been run on an iPad Gen 10; native mouse movement from the iPad across to the HDMI workspace is not an implemented or supported capability.

`UIApplicationSupportsIndirectInputEvents` is not added to the generated Info.plist. Apple's documented default is `YES` on iOS 17 and later, and this iOS 27 target uses SwiftUI hover/gesture APIs rather than custom raw `UITouch` routing.
