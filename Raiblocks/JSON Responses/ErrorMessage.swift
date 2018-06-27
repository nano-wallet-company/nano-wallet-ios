//
//  ErrorMessage.swift
//  Nano
//
//  Created by Zack Shapiro on 12/19/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

enum ErrorMessageType: String, Decodable {

    case accountNotFound = "Account not found"
    case fork = "Fork"
    case oldBlock = "Old block"

    var description: String {
        return self.rawValue
    }

}

struct ErrorMessage: Decodable {

    let error: ErrorMessageType

}
