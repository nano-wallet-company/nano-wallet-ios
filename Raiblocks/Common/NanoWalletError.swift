//
//  NanoWalletError.swift
//  Nano
//
//  Created by Zack Shapiro on 1/23/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

enum NanoWalletError: Error {

    case longUsableStringCastFailed

    case credentialStorageError
    case currencyStorageError

    case unableToGetCurrentUserSeed
    case unableToGenerateSignature
    case unableToGenerateWork

    case blockWrappingFailed

    case socketConnectionWasClosed
    case socketEventError

    case logOutError

    case unableToGetKeychainKeyID
    case unableToFetchCredentials
    case unableToUpdateCredentialsWithUUID
    case unableToUpdateCredentialsWithLegalAgreement
    case unableToUpdateCredentialsWithAnalyticsAgreement
}
