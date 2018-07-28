//
//  DeepLinkParser.swift
//  Raiblocks
//
//  Created by Fawaz Tahir on 7/28/18.
//  Copyright © 2018 Zack Shapiro. All rights reserved.
//

import Foundation

final class DeepLinkParser {
    
    func deepLinkType(from url: URL) -> DeepLink? {
        guard let deepLinkURL = DeepLinkURL(url: url), let destination = deepLinkURL.destination else {
            return nil
        }
        return DeepLink(url: url, destination: destination, parameters: url.queryDictionary)
    }
}

extension AddressParser {
    
    enum QueryParameter: String {
        case address
        case amount
    }
    
    static func parseDeepLink(queryParameters: DeepLink.Parameters?) -> TransactionMeta? {
        guard let parameters = queryParameters else {
            return nil
        }
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
