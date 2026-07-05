# awake-mac

A lightweight macOS menu bar utility that prevents your Mac from sleeping. Built with Swift and SwiftUI — no Xcode project required.

## Why

macOS puts your MacBook to sleep when you close the lid — unless it detects an external display. awake-mac solves this by creating a virtual display that tricks macOS into thinking a monitor is connected. This keeps your MacBook fully awake with the lid closed, which is useful for running long tasks, downloads, remote access, or acting as a headless server without needing a physical monitor plugged in.

## Features

- **Prevent Sleep** — Uses IOKit power assertions to stop the system from sleeping
- **Keep Network Active** — Maintains WiFi connectivity while awake
- **Auto-off Timer** — Automatically disables after 1, 2, or 4 hours
- **Virtual Display** — Creates a fake 3840x2160 display so macOS stays awake even with the lid closed (clamshell mode), no external monitor required
- **Awake & Lock** — Enables awake + virtual display, then locks the screen in one click — perfect for closing the lid and walking away
- **Launch at Login** — Optionally start on login via macOS ServiceManagement

## Requirements

- macOS 13.0+ (Ventura or later)
- Apple Silicon (arm64)
- Xcode Command Line Tools (`xcode-select --install`)

## Build

```bash
./build.sh
```

This compiles all Swift sources with `swiftc`, creates a `.app` bundle, and generates the app icon.

## Run

```bash
open build/Awake.app
```

## Install

```bash
cp -r build/Awake.app /Applications/
```

## Usage

The app runs entirely in the menu bar (no Dock icon).

| Icon | State |
|------|-------|
| Coffee cup | Awake is active |
| Moon/zzz | Awake is inactive |

Click the menu bar icon to open the controls:

- **Awake toggle** — Enable or disable sleep prevention
- **Timer** — Set auto-off duration (Off, 1h, 2h, 4h)
- **Virtual Display** — Toggle the virtual display for headless/clamshell use
- **Awake & Lock** — Activate awake mode and immediately lock the screen
- **Launch at Login** — Start automatically when you log in

The app remembers its enabled state between launches.

## How It Works

| Component | Mechanism |
|-----------|-----------|
| Sleep prevention | `kIOPMAssertPreventUserIdleSystemSleep` power assertion |
| Network keep-alive | `kIOPMAssertNetworkClientActive` power assertion |
| Virtual display | Private `CGVirtualDisplay` API (3840x2160 @ 60Hz) |
| Screen lock | Private `SACLockScreenImmediate` from the login framework |
| Launch at login | `SMAppService` (macOS 13+) |

## Notes

- The app uses private Apple APIs for virtual display and screen locking. It is intended for local/personal use and is not signed for distribution.
- Bundle ID: `com.local.awake`

## License

Personal use.
