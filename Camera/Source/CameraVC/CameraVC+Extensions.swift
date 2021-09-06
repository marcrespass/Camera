//
//  CameraVC+Extensions.swift
//  CameraVC+Extensions
//
//  Created by Marc Respass on 9/6/21.
//  Copyright © 2021 ILIOS Inc. All rights reserved.
//

import AppKit
import AVKit

@objc public extension CameraVC {
    // MARK: - Notifications
    func toggleMirrorPreview(_ notification: Notification) {
        guard let mirrored = UserDefaults.standard.value(for: .mirrorPreview),
              let connection = self.videoPreviewLayer.connection else { return }

        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = mirrored
    }

    // MARK: - UserDefaults methods
    // Mirror the connection for the video preview layer
    func configureVideoMirrored(_ vpLayer: AVCaptureVideoPreviewLayer) {
        guard let mirrored = UserDefaults.standard.value(for: .mirrorPreview),
              let connection = vpLayer.connection else { return }

        DispatchQueue.main.async {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = true
                connection.isVideoMirrored = mirrored
            }

        }
    }

    func handlePostImageOperation(at url: URL) {
        let open = UserDefaults.standard.value(for: .openSavedImage) ?? false
        let show = UserDefaults.standard.value(for: .showSavedImage) ?? false

        if open {
            NSWorkspace.shared.open(url)
        }
        if show {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    func copyRecognizedTextToPasteboard(_ text: String) {
        guard let copy = UserDefaults.standard.value(for: .copyRecognizedText) else { return }
        let pasteboard = NSPasteboard.general
        if copy {
            pasteboard.clearContents()
            if !pasteboard.writeObjects([text as NSString]) {
                NSAlert().ilios_alert(withTitle: "Recognized text", message: "Copy text to pasteboard failed.").runModal()
            }
        }
    }

    // MARK: - Wrappers
    func shouldFlashScreen() -> Bool {
        return UserDefaults.standard.value(for: .flashScreen) ?? false
    }

    func shouldUseCountdown() -> Bool {
        return UserDefaults.standard.value(for: .useCountdown) ?? false
    }

    func mirrorSavedImage() -> Bool {
        return UserDefaults.standard.value(for: .mirrorSavedImage) ?? false
    }

    func mirrorPreview() -> Bool {
        return UserDefaults.standard.value(for: .mirrorPreview) ?? false
    }

    func recognizeText() -> Bool {
        return UserDefaults.standard.value(for: .recognizeText) ?? false
    }
}
