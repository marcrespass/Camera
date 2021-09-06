//
//  UserDefaults+Extensions.swift
//
//  Created by Marc Respass on 6/29/16.
//  Copyright © 2016-2019 ILIOS Inc. All rights reserved.
//

// https://danieltull.co.uk//blog/2019/10/09/type-safe-user-defaults/

import Foundation

extension UserDefaults {
    public struct Key<Value> {
        public let name: String
        public init(_ name: String) {
            self.name = name
        }
    }

    public func configureDefaults() {
        let defaultsDictionary: [String: Any] = [
            "MirrorPreview": true,
            "MirrorSavedImage": true,
            "ShowSavedImage": true,
            "OpenSavedImage": false,
            "RecognizeText": false,
            "CopyRecognizedText": false,
            "UseCountdown": true,
            "FlashScreen": true
        ]
        self.register(defaults: defaultsDictionary)
    }
}

extension UserDefaults {
    public func value<Value>(for key: Key<Value>) -> Value? {
        return object(forKey: key.name) as? Value
    }

    public func set<Value>(_ value: Value, for key: Key<Value>) {
        set(value, forKey: key.name)
    }

    public func removeValue<Value>(for key: Key<Value>) {
        removeObject(forKey: key.name)
    }
}

// MARK: - UserDefaults.Key Extensions
extension UserDefaults.Key where Value == Bool {
    public static let mirrorPreview = Self("MirrorPreview")
    public static let mirrorSavedImage = Self("MirrorSavedImage")
    public static let showSavedImage = Self("ShowSavedImage")
    public static let openSavedImage = Self("OpenSavedImage")
    public static let recognizeText = Self("RecognizeText")
    public static let copyRecognizedText = Self("CopyRecognizedText")
    public static let useCountdown = Self("UseCountdown")
    public static let flashScreen = Self("FlashScreen")
}
