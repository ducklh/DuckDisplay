# DuckDisplay (non-jailbreak external-display PoC)

A minimal SwiftUI app for iPadOS 27 that presents app-owned content on a connected external display using Apple's public `ExternalNonInteractiveAccessory` / `UISceneAccessory.externalNonInteractive` API. UIKit screen notifications provide connection, disconnection, and display-mode diagnostics; iPadOS owns presentation and lifecycle of the external scene.

## What this PoC does

- Runs as a normal, non-jailbroken iPad app.
- Keeps a control interface on the iPad.
- Registers a non-interactive external-display accessory.
- Presents a separate DuckDisplay workspace on a connected HDMI/DisplayPort display.
- Shares one `WorkspaceStore` between the iPad control screen and external workspace.
- Reports detected display bounds, current video mode, native resolution, and whether the accessory view is visible.
- Refreshes display information on connect, disconnect, and mode-change notifications.
- Adapts the external workspace layout to the available scene size and orientation.

## Important limitations

This is **app-level extended content**, not a system-wide extended iPad desktop.

- It cannot move Safari, Telegram, Settings, or other third-party iPad apps onto the monitor.
- The external accessory scene is non-interactive; control is performed on the iPad.
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

Open `DuckDisplay.xcodeproj`, select the DuckDisplay target, set your Development Team under Signing & Capabilities, select the connected iPad, and Build & Run. For an unsigned device-independent build check:

```bash
xcodebuild -project DuckDisplay.xcodeproj -scheme DuckDisplay \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

To install on iPad, use Xcode's Run action with the device selected and a valid Development Team. A connected-device deployment cannot be verified from a Linux host.

## HDMI and display test cases

Run on the iPad Gen 10 with a USB-C HDMI/DisplayPort adapter and a physical monitor; the simulator cannot verify this display lifecycle.

1. **No display at launch:** Open DuckDisplay with HDMI disconnected. Confirm Control Center and its workspace controls remain usable and the status says no external display is detected.
2. **Connect:** Connect HDMI while the app is foregrounded. Confirm the status changes to display detected, bounds/mode are reported, and iPadOS presents the external workspace.
3. **Independent control:** Change Panel, Headline, Description, and Show clock on the iPad. Confirm the iPad remains on Control Center and the external workspace reflects those changes.
4. **Disconnect:** Unplug HDMI. Confirm the iPad UI remains responsive, display status clears, and the app does not crash.
5. **Reconnect:** Reconnect HDMI. Confirm the external workspace reappears and reports the new display configuration without relaunching the app.
6. **Orientation and resolution:** Rotate the iPad and change monitor input/mode (for example 1080p to another supported mode). Confirm the scene relayouts and display bounds/current mode refresh.
7. **Unsupported configuration:** Try an unsupported adapter/mode. Confirm Control Center remains usable and does not claim that a workspace is active when iPadOS has not presented it.

## Project structure

```text
DuckDisplay/
├── App/DuckDisplayApp.swift
├── Core/WorkspaceStore.swift
├── Display/ExternalDisplayMonitor.swift
├── Display/ExternalWorkspaceView.swift
└── UI/ControlCenterView.swift
```

## Build verification

The project targets iPadOS 27 and Swift 6. Build it with Xcode 27 or later and the iPadOS 27 SDK using the command above. Verify deployment and HDMI test cases on a physical iPad Gen 10; the external display path is not testable on this Linux development environment or the iOS simulator.
