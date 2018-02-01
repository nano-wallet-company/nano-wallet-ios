//
//  Endpoint.swift
//  Nano
//
//  Created by Zack Shapiro on 12/11/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import Crashlytics


enum Endpoint {
    case accountBlockCount(address: Address)
    case accountBalance(address: Address)
    case accountCheck(address: Address)
    case accountHistory(address: Address, count: Int)
    case accountInfo(address: Address)
    case accountPending(address: Address)
    case accountsPending(address: Address, count: Int)
    case accountSubscribe(address: Address)

    case createOpenBlock(source: String, work: String, representative: String, address: Address, privateKey: Data)
    case createReceiveBlock(previous: String, source: String, work: String, privateKey: Data)
    case createSendBlock(destination: Address, balanceHex: String, previous: String, work: String, privateKey: Data)

    private var name: String {
        switch self {
        case .accountBlockCount: return "account_block_count"
        case .accountBalance: return "account_balance"
        case .accountCheck: return "account_check"
        case .accountHistory: return "account_history"
        case .accountInfo: return "account_info"
        case .accountPending: return "pending" // Pending is for 1 account
        case .accountsPending: return "accounts_pending" // Accounts Pending is for all accounts
        case .accountSubscribe: return "account_subscribe"
        case .createOpenBlock, .createReceiveBlock, .createSendBlock: return "process"
        }
    }

    func stringify() -> String? {
        var dict: [String: Any] = [:]
        dict["action"] = name

        switch self {
        case let .accountBalance(address),
             let .accountBlockCount(address),
             let .accountCheck(address),
             let .accountInfo(address),
             let .accountSubscribe(address):
            dict["account"] = address.longAddress

        case let .accountHistory(address, count):
            dict["account"] = address.longAddress
            dict["count"] = count + 5

        case let .accountPending(address):
            dict["account"] = address.longAddress
            dict["count"] = 10 // not using count, new users will likely not have this many txns
            dict["source"] = "true" // this should eventually be a bool, not a string

        case let .accountsPending(address, count):
            dict["accounts"] = [address.longAddress]
            dict["count"] = count

        case let .createOpenBlock(source, work, representative, address, privateKey):
            var block: [String: String] = Endpoint.createEmptyBlock(forTransactionType: .open)
            block["source"] = source
            block["representative"] = representative
            block["account"] = address.longAddress
            block["work"] = work

            guard let signedBlock = Endpoint.generateSignature(forDictionary: block, andPrivateKey: privateKey) else { return nil }
            dict["block"] = signedBlock

            guard let serializedJSON = try? JSONSerialization.data(withJSONObject: dict) else { return nil }

            return String(bytes: serializedJSON, encoding: .utf8)

        case let .createReceiveBlock(previous, source, work, privateKey):
            var block: [String: String] = Endpoint.createEmptyBlock(forTransactionType: .receive)
            block["previous"] = previous
            block["source"] = source
            block["work"] = work

            guard let signedBlock = Endpoint.generateSignature(forDictionary: block, andPrivateKey: privateKey) else { return nil }
            dict["block"] = signedBlock

            guard let serializedJSON = try? JSONSerialization.data(withJSONObject: dict) else { return nil }

            return String(bytes: serializedJSON, encoding: .utf8)

        case let .createSendBlock(destination, balanceHex, previous, work, privateKey):
            var block: [String: String] = Endpoint.createEmptyBlock(forTransactionType: .send)
            block["destination"] = destination.longAddress
            block["balance"] = balanceHex // this is a hexified string
            block["previous"] = previous
            block["work"] = work

            guard let signedBlock = Endpoint.generateSignature(forDictionary: block, andPrivateKey: privateKey) else { return nil }
            dict["block"] = signedBlock

            guard let serializedJSON = try? JSONSerialization.data(withJSONObject: dict) else { return nil }

            return String(bytes: serializedJSON, encoding: .utf8)
        }

        guard let serializedJSON = try? JSONSerialization.data(withJSONObject: dict) else { return nil }

        return String(bytes: serializedJSON, encoding: .utf8)
    }

    static func createWorkForOpenBlock(publicKey: String) -> Data? {
        let dict: [String: String] = [
            "action": "work_generate",
            "hash": publicKey
        ]

        return try? JSONSerialization.data(withJSONObject: dict)
    }

    static func createWork(previousHash previous: String) -> Data? {
        let dict: [String: String] = [
            "action": "work_generate",
            "hash": previous
        ]

        return try? JSONSerialization.data(withJSONObject: dict)
    }

    // MARK: - Private Functions

    private static func createEmptyBlock(forTransactionType type: TransactionType) -> [String: String] {
        return ["type": type.rawValue, "signature": "0"]
    }

    private static func generateSignature(forDictionary dict: [String: String], andPrivateKey key: Data) -> String? {
        guard
            let data = try? JSONSerialization.data(withJSONObject: dict),
            let string = String(data: data, encoding: .utf8),
            let signedBlock = RaiCore().signTransaction(string, withPrivateKey: key).asUTF8Data()
        else {
            Crashlytics.sharedInstance().recordError(NanoWalletError.unableToGenerateSignature)

            return nil
        }

        guard
            let signedDict = try? JSONSerialization.jsonObject(with: signedBlock) as! [String: String],
            let sig = try? JSONSerialization.data(withJSONObject: signedDict),
            let block = String(data: sig, encoding: .utf8)
        else {
            Crashlytics.sharedInstance().recordError(NanoWalletError.blockWrappingFailed)

            return nil
        }

        return block
    }

}
