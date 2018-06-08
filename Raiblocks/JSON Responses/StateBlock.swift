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

protocol NanoBlockType {
    var type: TransactionType { get }
    var account: String { get }
    var signature: String { get }
    var work: String { get }

    var accountAddress: Address { get }
    var transactableBalance: NSDecimalNumber { get }

    var asStringifiedDictionary: String? { get }
}

struct StateBlock: Decodable, NanoBlockType {

    let type: TransactionType
    internal let account: String
    let previous: String
    internal let balance: String
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

    /// It's safer to require the client to call .longAddress on this to get the string rather than exposing the string version of `representative` above
    var representativeAddress: Address {
        return Address(representative)!
    }

    var transactableBalance: NSDecimalNumber {
        return NSDecimalNumber(string: balance)
    }

    var asStringifiedDictionary: String? {
        let dict: [String: String] = [
            "account": account,
            "previous": previous,
            "representative": representative,
            "balance": balance,
            "link": link,
            "type": "state"
        ]

        guard let serializedJSON = try? JSONSerialization.data(withJSONObject: dict) else { return nil }

        return String(bytes: serializedJSON, encoding: .utf8)
    }

}

struct LegacyBlock: Decodable, NanoBlockType {

    internal let account: String
    private let destination: String?
    let representative: String?
    let source: String? // receives and opens had `source`s
    let amount: String
    let type: TransactionType
    let previous: String?
    let work: String
    let signature: String
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

    var asStringifiedDictionary: String? {
        let dict: [String: String?] = [
            "type": type.rawValue,
            "account": account,
            "balance": amount,
            "previous": previous,
            "destination": destination,
            "representative": representative,
            "source": source
        ]

        guard let serializedJSON = try? JSONSerialization.data(withJSONObject: dict) else { return nil }

        return String(bytes: serializedJSON, encoding: .utf8)
    }

}
