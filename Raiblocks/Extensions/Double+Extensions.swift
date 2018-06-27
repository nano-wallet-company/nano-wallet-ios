//
//  Double+Extensions.swift
//  Nano
//
//  Created by Zack Shapiro on 2/25/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

extension Double {

    /// Turns 0.056 into 0.6 and 0.054 into 0.5
    mutating func roundTo2f() -> Double {
        return Double(Darwin.round(100 * self)/100)
    }

}
