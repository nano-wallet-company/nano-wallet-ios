//
//  AccountInfo.swift
//  Nano
//
//  Created by Zack Shapiro on 12/23/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

/// This is used to get the Frontier hash before any request that requires it
struct AccountInfo: Decodable {

    let frontier: String
    private let balance: String
    private let _representative: String?

    var transactableBalance: NSDecimalNumber {
        return NSDecimalNumber(string: balance)
    }

    var representative: Address? {
        guard let rep = _representative else { return nil }

        return Address(rep)
    }

}
