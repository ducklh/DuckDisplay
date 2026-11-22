# Technical boundaries

## Supported path

Use Apple's public external-display accessory API:

- SwiftUI `.sceneAccessory { ExternalNonInteractiveAccessory { ... } }`
- UIKit `UISceneAccessory.externalNonInteractive(sceneConfiguration:)`
- External scene role: `windowExternalDisplayNonInteractive`

The external display is an app-owned, full-screen, non-interactive presentation surface.

## Unsupported goal on iPad Gen 10

A third-party app cannot turn the A14 iPad into a system-wide interactive extended desktop equivalent to Stage Manager on M-series iPads. That would require OS-level support from Apple. Jailbreak is not part of this project and would not guarantee the capability.

## Acceptance criteria for the PoC

- The iPad control UI remains usable.
- The HDMI display shows content different from the iPad UI.
- Changes on the iPad update the external content.
- HDMI disconnect/reconnect does not crash the app.
- No jailbreak, private API, or Mac-side host is required.
