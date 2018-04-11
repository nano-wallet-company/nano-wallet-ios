//
//  HashReceive.swift
//  Nano
//
//  Created by Zack Shapiro on 12/26/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

/// `hash` becomes `previous` for the next block that needs to be sent
struct HashReceive: Decodable {

    let hash: String

}
