# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Simple Camera** — a sandboxed macOS app for selecting a camera and taking pictures. Images are saved as JPEG to `NSTemporaryDirectory()` and optionally opened or revealed in Finder. The app also supports OCR on captured or dragged images via the Vision framework. Localized in English and Spanish.

- **Deployment target:** macOS 12.0
- **Bundle ID:** `com.iliosinc.Camera`
- **Language mix:** Objective-C (core camera logic) + Swift (extensions, preferences, OCR)

## Build & Lint

Build and run via Xcode — open `Camera.xcodeproj`.

SwiftLint runs as a build phase. To lint manually:
```
swiftlint Camera/
```
SwiftLint config: `.swiftlint.yml` (opt-in: `empty_count`; disabled: `trailing_whitespace`, `switch_case_alignment`, `line_length`).

`SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` — all Swift warnings are build errors.

## Architecture

### Object Graph

```
AppDelegate
  └── AppController              (owns the main window + OCR windows)
        └── CameraVC             (Obj-C, main view controller)
              ├── CountdownViewController  (Obj-C, countdown before capture)
              ├── PreferencesVC            (Swift, shown as a popover)
              └── DraggingView             (Swift, accepts drag-and-drop image files)
```

### Key Classes

| File | Role |
|---|---|
| `AppController.swift` | Creates/owns `NSWindow` for `CameraVC`; handles OCR result windows; implements `OCRDelegate` |
| `CameraVC.m` (Obj-C) | All AVFoundation capture logic: session setup, device selection/switching, photo capture, flash, countdown |
| `CameraVC+Extensions.swift` | Swift extensions on `CameraVC`: UserDefaults helpers, `DraggingViewDelegate` conformance |
| `NSData+Extensions.swift` | `recognizeText(completionHandler:)` via Vision; `nsImage(mirrored:)` for post-capture mirroring |
| `CGImage+Extensions.swift` | `rotating(to:)` — manual image mirroring/rotation (M1 workaround: `AVCapturePhotoOutput` cannot mirror its connection on M1) |
| `ImageOCRVC.swift` | Shows a recognized-text window next to the captured image |
| `UserDefaults+Extensions.swift` | Type-safe `UserDefaults.Key<Value>` API; all preference keys defined here |

### Swift ↔ Obj-C Bridge

The bridging header (`Camera-Bridging-Header.h`) exposes `CameraVC.h` and `NSAlert+ILIOSAdditions.h` to Swift. `CameraVC.m` imports `Camera-Swift.h` to call `DraggingView`, `PreferencesVC`, and the Swift extensions.

### UserDefaults Keys

All keys are `Bool` and declared in `UserDefaults+Extensions.swift`:
`mirrorPreview`, `mirrorSavedImage`, `showSavedImage`, `openSavedImage`, `recognizeText`, `copyRecognizedText`, `useCountdown`, `flashScreen`.

### OCR Flow

1. `CameraVC` calls `ocrDelegate.displayRecognizedText(_:)` (or `displayRecognizedTextAtURL:` for drag/open).
2. `AppController` (the delegate) calls `NSData.recognizeText(completionHandler:)` which uses `VNRecognizeTextRequest`.
3. Result text is shown in a new `ImageOCRVC` window, cascaded relative to the previous OCR window.

## XCConfig Structure

Build settings are in `XCConfig/`:
- `1XcodeWarnings.xcconfig` — warning flags
- `2Project-Shared.xcconfig` — shared project settings (sandbox entitlements, deployment target, bundle prefix, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- `2Project-Version.xcconfig` — `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`
- `App-Shared.xcconfig` — app-specific settings (bridging header, privacy strings, `SWIFT_APPROACHABLE_CONCURRENCY`)
- Debug/Release variants split across `2Project-Debug/Release` and `App-Debug/Release`

## Launch Argument

Pass `-screenshots` to force the window to 1280×800 for App Store screenshot automation.
