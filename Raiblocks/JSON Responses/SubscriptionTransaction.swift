//
//  SubscriptionTransaction.swift
//  Nano
//
//  Created by Zack Shapiro on 12/22/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

struct SubscriptionTransaction: Decodable {

    private let account: String
    private let amount: String
    let block: StateBlock
    private let hash: String // `source` for receiveBlock transaction
    private let is_send: String

    var transactionType: TransactionType {
        return block.type
    }

    var source: String {
        return hash
    }

    var isSend: Bool {
        return is_send == "true"
    }

    var fromAddress: Address? {
        return Address(account)
    }

    /// This should be your wallet address
    var toAddress: Address? {
        return block.toAddress
    }

    var representative: Address? {
        return block.representativeAddress
    }

    var transactionAmount: NSDecimalNumber {
        return NSDecimalNumber(string: amount)
    }

}
