//
//  NSError+Extensions.swift
//  SoapHandler
//
//  Created by Marc Respass on 7/11/17.
//  Copyright © 2017 ILIOS Inc. All rights reserved.
//

import Foundation

extension NSError {
    convenience init(with string: String) {
        let userInfo = [NSLocalizedDescriptionKey: string]
        self.init(domain: NSCocoaErrorDomain, code: 2112, userInfo: userInfo)
    }

    convenience init(code: Int, string: String) {
        let userInfo = [NSLocalizedDescriptionKey: string]
        let domain = Bundle.main.bundleIdentifier ?? "missing.bundle.identifier"
        self.init(domain: domain, code: code, userInfo: userInfo)
    }

    convenience init(message403 string: String) {
        let userInfo = [NSLocalizedDescriptionKey: string]
        let domain = Bundle.main.bundleIdentifier ?? "missing.bundle.identifier"
        self.init(domain: domain, code: 403, userInfo: userInfo)
    }

    convenience init(message500 string: String) {
        let userInfo = [NSLocalizedDescriptionKey: string]
        let domain = Bundle.main.bundleIdentifier ?? "missing.bundle.identifier"
        self.init(domain: domain, code: 500, userInfo: userInfo)
    }
}
