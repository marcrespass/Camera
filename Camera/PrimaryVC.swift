//
//  PrimaryVC.swift
//  Template
//
//  Created by Marc Respass on 7/25/20.
//

import Cocoa

class PrimaryVC: NSViewController {
    weak var delegate: SomeDelegate?

    init(delegate: SomeDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    override var nibName: NSNib.Name? { NSNib.Name("PrimaryVC") }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented. Use init(delegate:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
