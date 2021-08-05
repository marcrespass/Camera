//
//  Preferences.swift
//  Camera
//
//  Created by Marc Respass on 8/5/21.
//  Copyright © 2021 ILIOS Inc. All rights reserved.
//

import Cocoa

class PreferencesVC: NSViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("unavailable use init() instead")
    }

    override var nibName: NSNib.Name? {
        let name = NSNib.Name("PreferencesVC")
        return name
    }

}
