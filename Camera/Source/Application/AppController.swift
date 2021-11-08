// Created by Marc Respass on 11/16/17.
// Copyright © 2017 ILIOS Inc. All rights reserved.
// Swift version: 4.0 – macOS: 10.12

import Cocoa
import AVFoundation

final class AppController {
    static let minSize = CGSize(width: 379, height: 290)

    var window: NSWindow?
    let captureDeviceDiscoverySession: AVCaptureDevice.DiscoverySession

    lazy var contentVC: CameraVC = {
        return CameraVC(captureDeviceDiscoverySession: self.captureDeviceDiscoverySession)
    }()

    init() {
        let deviceTypes = [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.externalUnknown]
        self.captureDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                                             mediaType: AVMediaType.video,
                                                                             position: .unspecified)
    }

    @objc func createNewWindow() {
        if self.window == nil {
            let window = NSWindow(contentViewController: self.contentVC)
            window.title = NSLocalizedString("Camera", comment: "")
            window.tabbingMode = .disallowed
            window.setFrameAutosaveName("MainWindowFrame")
            window.contentMinSize = AppController.minSize
            window.makeKeyAndOrderFront(nil)
            self.window = window
        } else {
            self.window?.makeKeyAndOrderFront(nil)
        }
    }
}
