//
//  AccountCheck.swift
//  Nano
//
//  Created by Zack Shapiro on 12/20/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

/// Checks to see if the address is live on the network, if the address has an `open` block associated with it
/// This account with have at least one trasaction
struct AccountCheck: Decodable {

    let ready: Bool

}
