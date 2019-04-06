//
//  QRCode.swift
//  Raiblocks
//
//  Created by Fawaz Tahir on 7/24/18.
//  Copyright © 2018 Zack Shapiro. All rights reserved.
//

import Foundation

struct QRCode {
    
    let address: Address
    let amount: NSDecimalNumber?
    
    init?(address string: String) {
        guard let parsedAddress = AddressParser.parse(string: string) else {
            return nil
        }
        self.address = parsedAddress.address
        self.amount = parsedAddress.amount
    }
}
