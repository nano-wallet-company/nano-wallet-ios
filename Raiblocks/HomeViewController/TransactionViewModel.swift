//
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import Foundation


final class TransactionViewModel {

    let type: TransactionType?
    let transactionHash: String?
    let address: Address?
    let amount: NSDecimalNumber

    init(item: NanoTransaction) {
        self.type = item.type
        self.transactionHash = item.hash
        self.address = item.fromAddress // does this mess up with sends
        self.amount = item.transactionAmount.rawAsUsableAmount
    }

}

