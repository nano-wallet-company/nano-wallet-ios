//
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

enum TransactionType: String, Codable {
    case open, send, receive, change, state
    
    var description: String {
        switch self {
        case .send:
            return "send".localized()
        case .receive:
            return "receive".localized()
        default:
            return self.rawValue
        }
    }
}

enum NanoTransaction: Equatable {

    case pending(PendingHistoryItem)
    case finished(AccountHistory.HistoryItem)

    var isPending: Bool {
        switch self {
        case .pending: return true
        case .finished: return false
        }
    }

    var hash: String? {
        switch self {
        case let .pending(txn): return txn.hash
        case let .finished(txn): return txn.hash
        }
    }

    var type: TransactionType? {
        switch self {
        case let .pending(txn): return txn.type
        case let .finished(txn): return txn.type
        }
    }

    var fromAddress: Address? {
        switch self {
        case let .pending(txn): return txn.fromAddress
        case let .finished(txn): return txn.fromAddress
        }
    }

    var transactionAmount: NSDecimalNumber {
        switch self {
        case let .pending(txn): return txn.transactionAmount
        case let .finished(txn): return txn.transactionAmount
        }
    }

    static func ==(lhs: NanoTransaction, rhs: NanoTransaction) -> Bool {
        return lhs.type == rhs.type &&
        lhs.isPending == rhs.isPending &&
        lhs.hash == rhs.hash &&
        lhs.fromAddress == rhs.fromAddress &&
        lhs.transactionAmount == rhs.transactionAmount
    }

}


/// Shows all of the past transactions for an account
struct AccountHistory: Decodable {

    let transactions: [AccountHistory.HistoryItem]

    enum CodingKeys: String, CodingKey {
        case transactions = "history"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.transactions = try container.decode([HistoryItem].self, forKey: .transactions)
    }

    struct HistoryItem: Decodable {

        let type: TransactionType?
        let isPending: Bool = false

        private let account: String
        private let amount: String
        let hash: String?

        var fromAddress: Address? {
            return Address(account)
        }

        var transactionAmount: NSDecimalNumber {
            return NSDecimalNumber(string: amount)
        }

    }

}


struct PendingHistoryItem: Decodable {

    let type: TransactionType? = nil
    private let amount: String

    private let source: String?
    private let link_as_account: String?

    let isPending: Bool = true // can remove, unused
    var hash: String?

    var fromAddress: Address? {
        if let source = source {
            return Address(source)
        } else if let source = link_as_account {
            return Address(source)
        } else {
            return nil
        }
    }

    var transactionAmount: NSDecimalNumber {
        return NSDecimalNumber(string: amount)
    }

    init(withHash hash: String, andAmount amount: String) {
        self.hash = hash
        self.amount = amount
        self.source = nil
        self.link_as_account = nil
    }

}
