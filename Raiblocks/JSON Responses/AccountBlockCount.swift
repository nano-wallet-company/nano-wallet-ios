//
//  AccountBlockCount.swift
//  Raiblocks
//
//  Created by Zack Shapiro on 12/13/17.
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

enum AccountBlockCountError: Error {
    case couldNotParseCount
}

// NOTE: Don't think i'm using this

/// Shows the total block count for an account, used with the AccountHistory endpoint. May not need this as this data
/// comes back with AccountSubscribe
struct AccountBlockCount: Decodable {

    let count: Int

    enum CodingKeys: String, CodingKey {
        case count = "block_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let _count = try container.decode(String.self, forKey: .count)

        guard let count = Int(_count) else { throw AccountBlockCountError.couldNotParseCount  }
        self.count = count
    }

}
