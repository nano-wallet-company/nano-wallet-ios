//
//  Endpoint.swift
//  Nano
//
//  Created by Zack Shapiro on 12/11/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

enum BlockType {
    case open(sendBlockHash: String)
    case receive(sendBlockHash: String)
    case send(destinationAddress: Address)
    case change // not currently used
}

enum Endpoint {
    case accountBlockCount(address: Address)
    case accountBalance(address: Address)
    case accountCheck(address: Address)
    case accountHistory(address: Address, count: Int)
    case accountInfo(address: Address)
    case accountPending(address: Address)
    case accountsPending(address: Address, count: Int)
    case accountSubscribe(uuid: String?, address: Address)

    case createStateBlock(type: BlockType, previous: String, remainingBalance: String, work: String, fromAccount: Address, representative: Address, privateKey: Data)

    case createWorkForOpenBlock(publicKey: String)
    case createWork(previousHash: String)

    case getBlock(frontierHash: String)

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
        case .createWork, .createWorkForOpenBlock: return "work_generate"
        case .createStateBlock: return "process"
        case .getBlock: return "block"
        }
    }

    func stringify() -> String? {
        var dict: [String: Any] = [:]
        dict["action"] = name

        switch self {
        case let .accountBalance(address),
             let .accountBlockCount(address),
             let .accountCheck(address),
             let .accountInfo(address):
            dict["account"] = address.longAddress

        case let .accountSubscribe(uuid, address):
            if let uuid = uuid {
                dict["uuid"] = uuid
            } else {
                dict["account"] = address.longAddress
            }

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

        case let .createStateBlock(type, previous, remainingBalance, work, fromAccount, representative, privateKey):
            var block: [String: String] = Endpoint.createEmptyBlock(forTransactionType: .state)

            switch type {
            case let .open(hash):
                block["link"] = hash
                block["previous"] = "0"

            case let .receive(hash):
                block["link"] = hash
                block["previous"] = previous

            case let .send(destinationAddress):
                block["link"] = destinationAddress.longAddress
                block["previous"] = previous

            case .change:
                block["link"] = "0"
                block["previous"] = previous
            }

            block["representative"] = representative.longAddress
            block["account"] = fromAccount.longAddress
            block["balance"] = remainingBalance
            block["work"] = work

            // generate signature with new lib
            let signedBlock = Endpoint.generateSignature(forDictionary: block, andPrivateKey: privateKey)
            dict["block"] = signedBlock

            guard let serializedJSON = try? JSONSerialization.data(withJSONObject: dict) else { return nil }

            return String(bytes: serializedJSON, encoding: .utf8)

        case let .createWork(hash), let .createWorkForOpenBlock(hash), let .getBlock(hash):
            dict["hash"] = hash
        }

        guard let serializedJSON = try? JSONSerialization.data(withJSONObject: dict) else { return nil }

        return String(bytes: serializedJSON, encoding: .utf8)
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
            AnalyticsEvent.trackCrash(error: .unableToGenerateSignature)

            return nil
        }

        guard
            let signedDict = try? JSONSerialization.jsonObject(with: signedBlock) as! [String: String],
            let sig = try? JSONSerialization.data(withJSONObject: signedDict),
            let block = String(data: sig, encoding: .utf8)
        else {
            AnalyticsEvent.trackCrash(error: .blockWrappingFailed)

            return nil
        }

        return block
    }

}
