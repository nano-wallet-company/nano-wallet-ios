//
//  AnalyticsEvent.swift
//  Nano
//
//  Created by Zack Shapiro on 4/2/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
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
    case errorGeneratingWorkForSending = "Error Generating Work for Sending"
    case errorUnwrappingLocalCurrencyText = "Error unwrapping Local Currency text"
    case localCurrencySelected = "Local Currency Selected"
    case logOut = "User Logged Out"
    case missingCredentials = "App crashed due to missing Credentials"
    case nanoAddressCopied = "Nano Address Copied"
    case receiveMathError = "Receive Math Error"
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
    case unableToValidateHeadBlock = "Unable to validate head block"


    // Legal
    case disclaimerAgreementToggled = "Mobile Disclaimer Agreement Toggled"
    case eulaAgreementToggled = "Mobile EULA Agreement Toggled"
    case privacyPolicyAgreementToggled = "Mobile Privacy Policy Agreement Toggled"

    case disclaimerViewed = "Mobile Disclaimer Viewed"
    case eulaViewed = "Mobile EULA Viewed"
    case privacyPolicyViewed = "Mobile Privacy Policy Viewed"

    // VCs Viewed
    case addressScanCameraViewed = "Address Scan Camera View Viewed"
    case homeViewed = "Home VC Viewed"
    case easterEggViewed = "Easter Egg Viewed"
    case legalViewed = "Legal VC Viewed"
    case receiveViewed = "Receive VC Viewed"
    case settingsViewed = "Settings VC Viewed"
    case seedScanCameraViewed = "Seed Scan Camera View Viewed"
    case sendViewed = "Send VC Viewed"

    // Price Service
    case errorGettingCMCPriceData = "Error getting CoinMarketCap price data"
    case errorGettingCCAPIPriceData = "Error getting Currency Converter API price data"
    case errorGettingExchangePriceData = "Error getting exchange price data"
    
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
