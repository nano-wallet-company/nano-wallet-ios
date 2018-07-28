//
//  DeepLink.swift
//  Raiblocks
//
//  Created by Fawaz Tahir on 7/28/18.
//  Copyright © 2018 Zack Shapiro. All rights reserved.
//

import Foundation

struct DeepLink {
    enum Destination {
        case home
        case view(TransactionMeta)
        case send(TransactionMeta?)
        case receive(TransactionMeta?)
        case settings
    }
    
    typealias Parameters = [String: String?]
    
    let url: URL
    let destination: Destination
    let parameters: Parameters?
}
