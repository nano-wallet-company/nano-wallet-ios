//
//  AccountBlockCount.swift
//  Nano
//
//  Created by Zack Shapiro on 12/13/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

enum AccountBlockCountError: Error {
    case couldNotParseCount
}

/// Shows the total block count for an account, used with the AccountHistory endpoint. May not need this as this data
/// comes back with AccountSubscribe
struct AccountBlockCount: Decodable {

    private let block_count: String

    var count: Int {
        return Int(block_count) ?? 0
    }

}
