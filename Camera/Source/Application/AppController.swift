// Created by Marc Respass on 11/16/17.
// Copyright © 2017 ILIOS Inc. All rights reserved.
// Swift version: 4.0 – macOS: 10.12

import Cocoa

private extension Selector {
    static let appWindowWillClose = #selector(AppController.appWindowWillClose)
}

final class AppController {

    let contentVC = ContentVC()
    var window: NSWindow?

    @objc func createNewWindow() {
        let window = NSWindow(contentViewController: self.contentVC)
        window.title = NSLocalizedString("Camera", comment: "")
        window.tabbingMode = .disallowed
        window.setFrameAutosaveName("CameraWindowFrame")
        window.contentMinSize = CGSize(width: 379, height: 278)
        window.makeKeyAndOrderFront(nil)
        self.window = window

        NotificationCenter.default.addObserver(self, selector: .appWindowWillClose,
                                               name: NSWindow.willCloseNotification,
                                               object: window)
    }
}

// MARK: - Notifications
extension AppController {
    @objc func appWindowWillClose(notification: Notification) {
        guard let window = notification.object as? NSWindow, window == self.window else { return }

        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification,
                                                  object: window)

        let frameDescriptor = window.frameDescriptor
        UserDefaults.standard.setValue(frameDescriptor, forKey: "CameraWindowFrame")
        self.window = nil
    }
}