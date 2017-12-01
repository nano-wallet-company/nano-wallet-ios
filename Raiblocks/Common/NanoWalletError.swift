//
//  NanoWalletError.swift
//  Raiblocks
//
//  Created by Zack Shapiro on 1/23/18.
//  Copyright © 2018 Zack Shapiro. All rights reserved.
//

enum NanoWalletError: Error {

    case longUsableStringCastFailed
    case credentialStorageError
    case unableToGetCurrentUserSeed
    case unableToGenerateWork

}
