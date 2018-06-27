//
//  PendingBlocks.swift
//  Nano
//
//  Created by Zack Shapiro on 12/12/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

/// Takes into account the addresses. Used for .accounts_pending
/// not used in code atm (12/26)
struct AccountPendingBlocks: Decodable {
    // First `String` key is an address
    let blocks: [String: [String: PendingHistoryItem]]
}

/// Doesn't take into account the address, used for .account_pending
struct PendingBlocks: Decodable {

    private (set) var blocks: [String: PendingHistoryItem]

    // I don't think this is needed anymore
    mutating func setPendingItemHashes() -> [String: PendingHistoryItem] {
        for (_, block) in blocks.enumerated() {
            blocks[block.key]?.hash = block.key
        }

        return blocks
    }

}

