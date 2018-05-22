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
    private let block: SendBlock
    private let hash: String // `source` for receiveBlock transaction

    struct SendBlock: Decodable {

        let type: TransactionType
        let destination: String

        enum CodingKeys: String, CodingKey {
            case type
            case destination = "link_as_account"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let _type = try! container.decode(String.self, forKey: .type)
            self.type = TransactionType(rawValue: _type)!

            self.destination = try container.decode(String.self, forKey: .destination)
        }

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

    var transactionAmount: NSDecimalNumber {
        return NSDecimalNumber(string: amount)
    }

}
