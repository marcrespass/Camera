//
//  DraggingView.swift
//  Camera
//
//  Created by Marc Respass on 11/21/21.
//  Copyright © 2021 ILIOS Inc. All rights reserved.
//

import Cocoa

@objc protocol DraggingViewDelegate: AnyObject {
    func didOpenDraggedFiles(fileURLs: [URL])
}

class DraggingView: NSView {
    @objc weak var delegate: DraggingViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        self.registerForDraggedTypes([
            NSPasteboard.PasteboardType.URL,
            NSPasteboard.PasteboardType.tiff,
            NSPasteboard.PasteboardType.png,
            NSPasteboard.PasteboardType.fileURL
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - NSDraggingDestination
extension DraggingView {
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    public override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        if let urls = self.urlsFromDraggingInfo(draggingInfo) as? [URL] {
            self.delegate?.didOpenDraggedFiles(fileURLs: urls)
            return true
        }
        return false
    }
    
    private func urlsFromDraggingInfo(_ draggingInfo: NSDraggingInfo) -> [Any]? {
        let pasteboard = draggingInfo.draggingPasteboard
        let options = [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true]

        let results = pasteboard.readObjects(forClasses: [NSURL.self], options: options)
        return results
    }
}
