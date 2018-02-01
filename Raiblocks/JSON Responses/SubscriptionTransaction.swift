//
//  SubscriptionTransaction.swift
//  Nano
//
//  Created by Zack Shapiro on 12/22/17.
//  Copyright © 2017 Nano. All rights reserved.
//

// NOTE: need to get new Frontier (use Account Info endpoint and JSON response)
struct SubscriptionTransaction : Decodable {

    private let account: String
    private let amount: String
    private let block: SendBlock
    private let hash: String // `source` for receiveBlock transaction

    struct SendBlock: Decodable {
        let type: TransactionType
        let destination: String // verify it's my address
    }

    var transactionType: TransactionType {
        return block.type
    }

    var source: String {
        return hash
    }

    var fromAddress: Address? {
        return Address(account)
    }

    /// This should be your wallet address
    var toAddress: Address? {
        return Address(block.destination)
    }

    var usableAmount: NSDecimalNumber {
        return NSDecimalNumber(string: amount)
    }

}
