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

    private let block_count: Int

    var count: Int {
        return block_count
    }

}
