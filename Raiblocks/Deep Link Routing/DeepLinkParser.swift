//
//  DeepLinkParser.swift
//  Raiblocks
//
//  Created by Fawaz Tahir on 7/28/18.
//  Copyright © 2018 Zack Shapiro. All rights reserved.
//

import Foundation

final class DeepLinkParser {
    
    func deepLink(from url: URL) -> DeepLink? {
        return DeepLink(url: url)
    }
}

extension AddressParser {
    
    enum QueryParameter: String {
        case address
        case amount
    }
    
    static func parseDeepLink(parameters: DeepLink.Parameters) -> TransactionMeta? {
        guard
            let addressString = parameters[QueryParameter.address.rawValue] as? String,
            let address = Address(addressString) else {
            return nil
        }
        let amount: NSDecimalNumber?
        if let amountString = parameters[QueryParameter.amount.rawValue] {
            amount = NSDecimalNumber(string: amountString)
        } else {
            amount = nil
        }
        return TransactionMeta(address: address, amount: amount)
    }
}
