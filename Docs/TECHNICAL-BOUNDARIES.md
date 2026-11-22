# Technical boundaries

## Supported path

Use Apple's public external-display accessory API:

- SwiftUI `.sceneAccessory { ExternalNonInteractiveAccessory { ... } }`
- UIKit `UISceneAccessory.externalNonInteractive(sceneConfiguration:)`
- External scene role: `windowExternalDisplayNonInteractive`

The external display is an app-owned, full-screen, non-interactive presentation surface. It can render a desktop-style arrangement of this app's own windows, but it does not receive guaranteed user input.
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
- External accessory content is rendered without hit testing. Touch, pointer, and keyboard input on the external display are unsupported; no external keyboard or mouse support is claimed. The iPad's interactive Control Center is the supported control path for opening, focusing, minimizing, restoring, maximizing, closing, moving, and resizing app windows.
- Window state is owned by one shared `WindowManager`; external scene geometry is used to clamp/rescale frames after display changes. `WorkspaceStore` continues to own the shared workspace content and display preferences.
- Monitor adapters, EDID negotiation, refresh rates, protected content, and available resolutions are controlled by iPadOS and the hardware. Unsupported combinations may leave the accessory unavailable.
- A14 hardware does not gain system-wide Stage Manager external-display support from this app.
