//
//  PrimaryVC.swift
//  Template
//
//  Created by Marc Respass on 7/25/20.
//

import Cocoa

private let myNibName = "ContentVC"

class ContentVC: NSViewController {
    lazy var cameraVC: CameraViewController = {
        let cvc = CameraViewController()
        self.addChild(cvc)
        return cvc
    }()

    override var nibName: NSNib.Name? { NSNib.Name(myNibName) }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented. Use init(delegate:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraVC.view.frame = self.view.bounds
        self.view.addSubview(self.cameraVC.view)
    }

}

extension ContentVC {
    fileprivate func constrainCurrentVCToEdges() {
        let constraints = [self.cameraVC.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                           self.cameraVC.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                           self.cameraVC.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                           self.cameraVC.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)]
        NSLayoutConstraint.activate(constraints)
    }

}
