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
    private let representative_block: String
    private let balance: String

    var representative: Address? {
        return Address(representative_block)
    }

    var transactableBalance: NSDecimalNumber {
        return NSDecimalNumber(string: balance)
    }

}
