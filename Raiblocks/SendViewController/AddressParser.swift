//
//  AddressParser.swift
//  Nano
//
//  Created by Zack Shapiro on 3/9/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

final class AddressParser {

    static func parse(string: String) -> (address: Address, amount: NSDecimalNumber?)? {
        if let address = Address(string) {
            return (address: address, amount: nil)
        }
        
        guard string.contains(":") else {
            return nil
        }
        
        let _addressString = string.split(separator: ":")[1]
        let addressString = _addressString.split(separator: "?")[0]
        
        guard let address = Address(String(addressString)) else { return nil }
        
        var amount: NSDecimalNumber? = nil
        if String(_addressString).contains("amount=") {
            // TODO: protect against strings formatted as 1,000.00
            let values = _addressString.split(separator: "=")
            
            guard values.count > 1 else { return (address: address, amount: nil) }
            let val = values[1].replacingOccurrences(of: ",", with: ".")
            amount = NSDecimalNumber(string: val).rawAsUsableAmount
        }
        
        return (address: address, amount: amount)
    }

}
