//
//  AnalyticsEvent.swift
//  Nano
//
//  Created by Zack Shapiro on 4/2/18.
//  Copyright © 2018 Nano. All rights reserved.
//

import Crashlytics
import Fabric


enum AnalyticsEvent: String {
    case badSeedViewed = "Alert for bad seed viewed"
    case badWalletSeedPasted = "Bad Wallet Seed Pasted"
    case createWorkFailed = "Create Work Failed"
    case createWorkFailedForOpenBlock = "Create Work For Open Block Failed"
    case endpointUnwrapFailed = "Endpoint Unwrap Failed"
    case errorParsingQRCode = "Error Parsing QR Code"
    case errorDecodingCMCBTCPriceData = "Error decoding CoinMarketCap BTC price data"
    case errorDecodingCMCNanoPriceData = "Error decoding CoinMarketCap Nano price data"
    case errorGettingCMCBTCPriceData = "Error getting CoinMarketCap BTC price data"
    case errorGettingCMCNanoPriceData = "Error getting CoinMarketCap Nano price data"
    case errorGettingExchangePriceData = "Error getting exchange price data"
    case errorGeneratingWorkForSending = "Error Generating Work for Sending"
    case errorUnwrappingLocalCurrencyText = "Error unwrapping Local Currency text"
    case localCurrencySelected = "Local Currency Selected"
    case missingCredentials = "App crashed due to missing Credentials"
    case nanoAddressCopied = "Nano Address Copied"
    case seedCopyFailed = "Seed Copy Failed"
    case seedCopied = "Seed Copied"
    case seedConfirmatonContinueButtonPressed = "Seed Confirmation Continue Button Pressed"
    case sendAddressFetchFailed = "Send VC Address Fetch Failed"
    case sendAuthError = "Error with Send Authentication"
    case sendBegan = "Send Nano Began"
    case sendFinished = "Send Nano Finished"
    case sendMaxAmountUsed = "Send: Max Amount Used"
    case sendWorkUnwrapFailed = "Send VC Send Nano Work Unwrap Failed"
    case shareDialogueViewed = "Share Dialogue Viewed"
    case socketClosedHome = "Socket Closed in HomeVM"
    case socketErrorHome = "socket Error in HomeVM"
    case logOut = "User Logged Out"

    // Legal
    case disclaimerAgreementToggled = "Mobile Disclaimer Agreement Toggled"
    case eulaAgreementToggled = "Mobile EULA Agreement Toggled"
    case privacyPolicyAgreementToggled = "Mobile Privacy Policy Agreement Toggled"

    case disclaimerViewed = "Mobile Disclaimer Viewed"
    case eulaViewed = "Mobile EULA Viewed"
    case privacyPolicyViewed = "Mobile Privacy Policy Viewed"

    // LocalCurrencyPair
    case errorFormattingLocalCurrencyStringToDouble = "Error formatting Local Currency String to Double"
    case errorInLocalCurrencyDecodeFunction = "Error in LocalCurrencyPair.decode function"
    case unableToGetLocalCurrencyPairBTCPrice = "Local Currency Pair Error: unable to get Bitcoin price"

    case errorFormattingNanoStringToDouble = "Error formatting Nano Price Pair String to Double"
    case errorInNanoDecodeFunction = "Error in NanoPricePair.decode function"
    case unableToGetNanoPrice = "Nano Price Pair Error: unable to get price"

    // VCs Viewed
    case addressScanCameraViewed = "Address Scan Camera View Viewed"
    case homeViewed = "Home VC Viewed"
    case easterEggViewed = "Easter Egg Viewed"
    case legalViewed = "Legal VC Viewed"
    case receiveViewed = "Receive VC Viewed"
    case settingsViewed = "Settings VC Viewed"
    case seedScanCameraViewed = "Seed Scan Camera View Viewed"
    case sendViewed = "Send VC Viewed"

    // MARK: - Functions

    // NOTE: Legal has track differently, has to record values
    func track(customAttributes: [String: Any]? = nil) {
        guard let credentials = UserService().fetchCredentials() else { return } // does this fail at legal?

        if credentials.hasAgreedToTracking || !credentials.hasAnsweredAnalyticsQuestion {
            Answers.logCustomEvent(withName: self.rawValue, customAttributes: customAttributes)
        }
    }

    static func trackCrash(error: NanoWalletError) {
        guard let credentials = UserService().fetchCredentials() else { return }

        if credentials.hasAgreedToTracking || !credentials.hasAnsweredAnalyticsQuestion {
            Crashlytics.sharedInstance().recordError(error)
        }
    }

    static func trackCustomException(_ text: String) {
        guard let credentials = UserService().fetchCredentials() else { return }

        if credentials.hasAgreedToTracking || !credentials.hasAnsweredAnalyticsQuestion {
            Crashlytics.sharedInstance().recordCustomExceptionName(text, reason: nil, frameArray: [])
        }
    }

}

final class AnalyticsService {

    static func start() {
        // Instantiate Crashlytics if APIKey and Secret are present
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
            let root = NSDictionary(contentsOfFile: path) as? [String: Any],
            let fabric = root["Fabric"] as? [String: Any],
            let _ = fabric["APIKey"] {
            Fabric.with([Crashlytics.self, Answers.self])
        } else {
            // print("No API Key Present")
        }
    }

    static func stop() {
        Fabric.with([])
    }

}
