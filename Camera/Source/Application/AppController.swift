// Created by Marc Respass on 11/16/17.
// Copyright © 2017 ILIOS Inc. All rights reserved.
// Swift version: 4.0 – macOS: 10.12

import Cocoa
import AVFoundation

final class AppController: NSObject {
    static let minSize = CGSize(width: 379, height: 290)

    var window: NSWindow?
    var ocrWindows: [NSWindow] = []
    let captureDeviceDiscoverySession: AVCaptureDevice.DiscoverySession

    lazy var mainContentVC: CameraVC = {
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
            let window = NSWindow(contentViewController: self.mainContentVC)
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
            self.displayRecognizedText(at: url)
        }
    }
}

extension AppController: OCRDelegate {
    func displayRecognizedText(_ image: NSImage) {
        guard let imageData = image.tiffRepresentation as NSData? else { return }

        imageData.recognizeText { result in
            switch result {
                case .success(let text):
                    let recognized = text.joined(separator: " ")
                    let imageVC = ImageOCRVC(recognizedText: recognized)

                    let window = NSWindow(contentViewController: imageVC)

                    window.tabbingMode = .disallowed
                    window.collectionBehavior = .fullScreenAuxiliary
                    window.contentMaxSize.height = imageVC.recognizedTextField.bounds.height + 40.0
                    window.delegate = self

                    window.position(relativeTo: self.ocrWindows.last, title: image.name())
                    imageVC.imageView.image = image
                    self.ocrWindows.append(window)

                    NSApp.activate(ignoringOtherApps: true)
                    window.makeKeyAndOrderFront(nil)
                    window.zoom(nil)
                case .failure(let error):
                    NSApp.presentError(error)
            }
        }
    }

    func displayRecognizedText(at fileURL: URL) {
        guard let image = NSImage(contentsOf: fileURL) else { return }
        let title = fileURL.deletingPathExtension().lastPathComponent
        image.setName(title)
        self.displayRecognizedText(image)
    }
}

extension AppController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let object = notification.object as? NSWindow {
            self.ocrWindows.removeAll { window in
                window == object
            }
        }
    }
}
