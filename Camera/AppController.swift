// Created by Marc Respass on 11/16/17.
// Copyright © 2017 ILIOS Inc. All rights reserved.
// Swift version: 4.0 – macOS: 10.12

import Cocoa

private extension Selector {
    static let appWindowWillClose = #selector(AppController.appWindowWillClose)
}

protocol SomeDelegate: class {
    func executeSearch()
}

final class AppController {

    lazy var contentVC: ContentVC = {
        let cvc = ContentVC(delegate: self)
        return cvc
    }()

    var windowControllers: [NSWindowController] = []

    @objc func createNewWindow() {
        let window = NSWindow(contentViewController: self.contentVC)
        window.title = NSLocalizedString("Camera", comment: "")
        let wc = NSWindowController(window: window)
        self.windowControllers.append(wc)

        wc.window?.center()
        wc.window?.makeKeyAndOrderFront(nil)

        NotificationCenter.default.addObserver(self, selector: .appWindowWillClose, name: NSWindow.willCloseNotification, object: wc.window)
    }
}

// MARK: - Notifications
extension AppController {
    @objc func appWindowWillClose(notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
        self.windowControllers.removeAll { window == $0.window }
    }

}

extension AppController: SomeDelegate {
    func executeSearch() {
        print("\(#function) not yet implemented")
    }

}
