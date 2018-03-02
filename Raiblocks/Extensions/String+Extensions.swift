//
//  String+Extensions.swift
//  Nano
//
//  Created by Zack Shapiro on 12/6/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import Foundation


extension String {

    func asUTF8Data() -> Data? {
        return self.data(using: .utf8)
    }

    func flatten() -> String {
        return self.replacingOccurrences(of: " ", with: "")
    }

    var entireRange: NSRange {
        return NSRange(location: 0, length: utf16.count)
    }

}
