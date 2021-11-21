//
//  ImageOCRVC.swift
//  Camera
//
//  Created by Marc Respass on 11/21/21.
//  Copyright © 2021 ILIOS Inc. All rights reserved.
//

import Cocoa

class ImageOCRVC: NSViewController {

    @IBOutlet weak var recognizedTextField: NSTextField!
    @IBOutlet weak var imageView: NSImageView!

    var recognizedText: String?

    init(recognizedText: String) {
        self.recognizedText = recognizedText
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("unavailable use init() instead")
    }

    override var nibName: NSNib.Name? {
        let name = NSNib.Name("ImageOCRVC")
        return name
    }

    override func viewDidLoad() {
        self.recognizedTextField.stringValue = self.recognizedText ?? "No recognized text found."
    }
}
