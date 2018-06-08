//
//  StateBlock.swift
//  Nano
//
//  Created by Zack Shapiro on 6/6/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

import Foundation

// This implementation can be better, will revisit
struct StateBlockContainer: Decodable {

    private let contents: String

    private var data: Data {
        return contents.asUTF8Data()!
    }

    var block: StateBlock {
        return try! JSONDecoder().decode(StateBlock.self, from: data)
    }

}

protocol NanoBlockType {}

struct StateBlock: Decodable, NanoBlockType {

    let type: TransactionType
    private let account: String
    let previous: String
    private let balance: String
    private let representative: String
    let link: String
    private let link_as_account: String
    let signature: String
    let work: String

    var accountAddress: Address {
        return Address(account)!
    }

    var toAddress: Address? {
        return Address(link_as_account)
    }

    var representativeAddress: Address {
        return Address(representative)!
    }

    var transactableBalance: NSDecimalNumber {
        return NSDecimalNumber(string: balance)
    }

}

struct LegacyBlock: Decodable, NanoBlockType {

    private let account: String
    private let destination: String?
    private let representative: String?
    private let source: String? // receives and opens had `source`s
    private let amount: String
    let type: TransactionType
    let previous: String?
    let work: String
    private let signature: String
    // let date: Date // come back later

    var accountAddress: Address {
        return Address(account)!
    }

    var toAddress: Address? {
        guard let string = destination else { return nil }

        return Address(string)
    }

    var representativeAddress: Address? {
        guard let string = representative else { return nil }

        return Address(string)
    }

    var transactableBalance: NSDecimalNumber {
        return NSDecimalNumber(string: amount)
    }

}
