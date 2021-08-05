//
//  AppDelegate.swift
//  Template
//
//  Created by Marc Respass on 7/25/20.
//

import Cocoa

@NSApplicationMain
final class AppDelegate: NSObject {
    let appController = AppController()

    override init() {
        let defaultsDictionary: [String: Any] = [
            "UseCountdown": true,
            "MirrorSavedImage": true,
            "MirrorPreview": true,
            "OCR": false,
            "FlashScreen": true
        ]
        UserDefaults.standard.register(defaults: defaultsDictionary)
    }
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.appController.createNewWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
