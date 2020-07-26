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
    @objc dynamic var finishedSetup = false

}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.appController.createNewWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
