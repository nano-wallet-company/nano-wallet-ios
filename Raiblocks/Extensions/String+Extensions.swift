//
//  String+Extensions.swift
//  Nano
//
//  Created by Zack Shapiro on 12/6/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
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

    // turns iLoveNano into "I Love Nano"
    func camelCaseToWords() -> String {
        return unicodeScalars.reduce("") {
            guard CharacterSet.uppercaseLetters.contains($1) else {
                return ($0 + String($1)).capitalized
            }

            return ($0 + " " + String($1)).capitalized
        }
    }

}
