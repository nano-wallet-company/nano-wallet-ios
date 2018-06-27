//
//  AccountBalance.swift
//  Nano
//
//  Created by Zack Shapiro on 12/12/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

/// Subscribes to an address on the network 
struct AccountSubscribe: Decodable {

    private let _blockCount: String
    private let balance: String
    private let _pendingBalance: String

    let frontierBlockHash: String
    let uuid: String?

    private let representative: String?

    enum CodingKeys: String, CodingKey {
        case _blockCount = "block_count"
        case balance
        case _pendingBalance = "pending"
        case representativeBlock = "representative_block"
        case frontierBlockHash = "frontier"
        case uuid
        case representative
    }

    var blockCount: Int {
        return Int(_blockCount) ?? 0
    }

    var representativeAddress: Address? {
        guard let rep = representative, let address = Address(rep) else { return nil }

        return address
    }

    var transactableBalance: NSDecimalNumber? {
        return NSDecimalNumber(string: balance)
    }

    var pendingBalance: NSDecimalNumber? {
        return NSDecimalNumber(string: _pendingBalance)
    }

    var totalBalance: NSDecimalNumber? {
        guard let pendingBalance = pendingBalance else { return nil }

        return transactableBalance?.adding(pendingBalance)
    }

    var totalBalanceAsString: String {
        return totalBalance?.rawAsUsableString ?? ""
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self._blockCount = try container.decode(String.self, forKey: ._blockCount)
        self.balance = try container.decode(String.self, forKey: .balance)
        self._pendingBalance = try container.decode(String.self, forKey: ._pendingBalance)
        self.frontierBlockHash = try container.decode(String.self, forKey: .frontierBlockHash)
        self.representative = try container.decode(String.self, forKey: .representative)

        if container.contains(.uuid) {
            self.uuid = try container.decode(String.self, forKey: .uuid)
        } else {
            self.uuid = nil
        }
    }

}
