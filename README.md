# DuckDisplay (non-jailbreak external-display PoC)

A minimal SwiftUI starter for iPadOS 27 that presents app-owned content on a connected external display using Apple's public `ExternalNonInteractiveAccessory` / `UISceneAccessory.externalNonInteractive` API.

## What this PoC does

- Runs as a normal, non-jailbroken iPad app.
- Keeps a control interface on the iPad.
- Registers a non-interactive external-display accessory.
- Presents a separate DuckDisplay workspace on a connected HDMI/DisplayPort display.
- Shares app state between the iPad control screen and external workspace.

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

Install XcodeGen, then run:

```bash
brew install xcodegen
cd DuckDisplay
xcodegen generate
open DuckDisplay.xcodeproj
```

Select the DuckDisplay target, set your Development Team under Signing & Capabilities, select the connected iPad, and Build & Run.

## Test plan

1. Launch DuckDisplay on the iPad without an external display. Confirm the control center works.
2. Connect the monitor through USB-C HDMI/DisplayPort.
3. Confirm iPadOS makes the external accessory scene available and shows the DuckDisplay workspace on the monitor.
4. Change Panel, Headline, and Description on the iPad. Confirm the external content updates.
5. Disconnect and reconnect HDMI. Confirm the app recovers without crashing.
6. Test portrait/landscape and 1080p/60Hz monitor modes.

## Project structure

```text
DuckDisplay/
├── App/DuckDisplayApp.swift
├── Core/WorkspaceStore.swift
├── Display/ExternalWorkspaceView.swift
└── UI/ControlCenterView.swift
```

## Next engineering steps

- Add explicit connection/availability diagnostics for the accessory registration.
- Persist workspace state with SwiftData.
- Add layout presets and app-owned panels.
- Add keyboard shortcuts and pointer support where UIKit delivers input to the iPad app.
- Add performance and reconnect telemetry.
