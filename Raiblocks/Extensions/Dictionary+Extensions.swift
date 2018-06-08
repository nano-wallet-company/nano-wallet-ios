//
//  Dictionary+Extensions.swift
//  Nano
//
//  Created by Zack Shapiro on 6/8/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

import Foundation

extension Dictionary {

    func serialize() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self)
    }

    var asSerializedString: String? {
        guard let data = serialize() else { return nil }

        return String(bytes: data, encoding: .utf8)
    }

}
