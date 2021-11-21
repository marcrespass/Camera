// Created by Marc Respass on 11/16/17.
// Copyright © 2017 ILIOS Inc. All rights reserved.
// Swift version: 4.0 – macOS: 10.12

import Cocoa
import AVFoundation

final class AppController: NSObject {
    static let minSize = CGSize(width: 379, height: 290)

    var window: NSWindow?
    let captureDeviceDiscoverySession: AVCaptureDevice.DiscoverySession

    lazy var contentVC: CameraVC = {
        let cvc = CameraVC(captureDeviceDiscoverySession: self.captureDeviceDiscoverySession)
        cvc.ocrDelegate = self
        return cvc
    }()

    override init() {
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

    func open(filenames: [String]) {
        self.createNewWindow()

        for path in filenames {
            let url = URL(fileURLWithPath: path)
            self.displayRecognizedText(url)
        }
    }
}

extension AppController: OCRDelegate {
    func displayRecognizedText(_ fileURL: URL) {
        guard let image = NSImage(contentsOf: fileURL),
              let imageData: NSData = image.tiffRepresentation as NSData? else { return }

        imageData.recognizeText { text, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            let recognized = text.joined(separator: " ")
            let imageVC = ImageOCRVC(recognizedText: recognized)

            let window = NSWindow(contentViewController: imageVC)
            window.title = NSLocalizedString("Recognized Text", comment: "")
            window.tabbingMode = .disallowed
            window.collectionBehavior = .fullScreenAuxiliary
            window.makeKeyAndOrderFront(nil)
            window.contentMaxSize.height = imageVC.recognizedTextField.bounds.height + 40.0
            window.zoom(nil)
        }
    }
}
