//
//  AppDelegate.swift
//  Template
//
//  Created by Marc Respass on 7/25/20.
//

import Cocoa

@NSApplicationMain
final class AppDelegate: NSObject {
    var didFinish = false
    let appController = AppController()

    override init() {
        UserDefaults.standard.configureDefaults()
    }
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.appController.createNewWindow()
        self.didFinish = true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MER 2021-09-08 Sometimes the app does not terminate on last window closed
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return self.didFinish
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        if self.didFinish {
            self.appController.createNewWindow()
        }
        return self.didFinish
    }

    func application(_ sender: NSApplication, openFile path: String) -> Bool {
        self.appController.open(filenames: [path])
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        self.appController.open(filenames: filenames)
    }
}
