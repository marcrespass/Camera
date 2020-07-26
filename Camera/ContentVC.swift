//
//  PrimaryVC.swift
//  Template
//
//  Created by Marc Respass on 7/25/20.
//

import Cocoa

fileprivate let myNibName = "ContentVC"

class ContentVC: NSViewController {
    weak var delegate: SomeDelegate?

    lazy var cameraVC: CameraViewController = {
        let it = CameraViewController()
        self.addChild(it)
        return it
    }()

    override var nibName: NSNib.Name? { NSNib.Name(myNibName) }

    init(delegate: SomeDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented. Use init(delegate:)") }

    override func viewDidLoad() {
        super.viewDidLoad()

        let mainView = self.view
        let cameraView = self.cameraVC.view

        self.view.window?.setContentSize(cameraView.bounds.size)

        cameraView.frame = mainView.bounds
        mainView.addSubview(cameraView)

        self.constrainCurrentVCToEdges()

        self.cameraVC.setupAVCaptureSession()
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
