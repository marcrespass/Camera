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
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.appController.createNewWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
