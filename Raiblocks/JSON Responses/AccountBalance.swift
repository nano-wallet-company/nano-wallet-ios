//
//  AccountBalance.swift
//  Nano
//
//  Created by Zack Shapiro on 12/12/17.
//  Copyright © 2017 Nano. All rights reserved.
//

// I may not need this anymore
struct AccountBalance: Decodable {

    private let _balance: String
    private let _pending: String

    enum CodingKeys: String, CodingKey {
        case balance = "balance"
        case pending = "pending"
    }

    var totalBalance: NSDecimalNumber? {
        guard
            let balance = try? UInt128(_balance),
            let pending = try? UInt128(_pending)
        else { return nil }

        let sum = balance + pending

        return NSDecimalNumber(string: sum._valueToString())
    }

    var transactableBalance: NSDecimalNumber? {
        guard let balance = try? UInt128(_balance) else { return nil }

        return NSDecimalNumber(string: balance._valueToString())
    }

    var totalBalanceAsString: String {
        return totalBalance?.rawAsUsableString ?? ""
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self._balance = try container.decode(String.self, forKey: .balance)
        self._pending = try container.decode(String.self, forKey: .pending)
    }

}
