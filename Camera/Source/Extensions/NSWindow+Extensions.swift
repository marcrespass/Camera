//
//  NSWindow+Extensions.swift
//  Camera
//
//  Created by Marc Respass on 11/28/21.
//  Copyright © 2021 ILIOS Inc. All rights reserved.
//

import AppKit

extension NSWindow {
    func position(relativeTo window: NSWindow?, title: String?) {
        if let lastWindow = window {
            var windowFrameOrigin = lastWindow.frame.origin
            windowFrameOrigin.y += lastWindow.frame.height - 20
            windowFrameOrigin.x += 20
            self.cascadeTopLeft(from: windowFrameOrigin)
        } else {
            self.center()
        }

        if let title = title {
            self.title = title
        } else {
            self.title = NSLocalizedString("Recognized Text", comment: "")
        }
    }
}
