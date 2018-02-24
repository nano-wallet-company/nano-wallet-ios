//
//  XRBPair.swift
//  Nano
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import Crashlytics


enum DecodableErrors: Error {
    case doubleCastError
    case priceError
}


struct LocalCurrencyPair {

    let currency: Currency

    func decode(fromData data: Data) throws -> Double {
        do {
            let coins = try JSONDecoder().decode([[String: String?]].self, from: data)
                .flatMap { $0 as? [String: String] }

            let numberFormatter = NumberFormatter()
            numberFormatter.maximumFractionDigits = 2
            numberFormatter.roundingMode = .halfUp

            if let dict = coins.first {
                if let _price = dict["price_\(currency.paramValue)"] {
                    if let price = numberFormatter.number(from: _price) {
                        return price.doubleValue
                    } else {
                        Answers.logCustomEvent(withName: "Local Currency Price unable to format", customAttributes: [:])
                        throw DecodableErrors.doubleCastError
                    }
                } else {
                    Answers.logCustomEvent(withName: "Local Currency unable to get value for dict key", customAttributes: [:])
                    throw DecodableErrors.doubleCastError
                }
            } else {
                Answers.logCustomEvent(withName: "Local Currency unable to get first coin", customAttributes: [:])
                throw DecodableErrors.doubleCastError
            }

            // temp
//            guard
//                let dict = coins.first,
//                let _price = dict["price_\(currency.paramValue)"],
//                let price = numberFormatter.number(from: _price)
//            else { throw DecodableErrors.doubleCastError }

//            return price.doubleValue
        } catch {
            Answers.logCustomEvent(withName: "Error in LocalCurrencyPair.decode function", customAttributes: [:])

            throw DecodableErrors.priceError
        }
    }

}

struct NanoPricePair {

    let currency: Currency
    
    func decode(fromData data: Data) throws -> Double {
        do {
            let coins = try JSONDecoder().decode([[String: String?]].self, from: data)
                .flatMap { $0 as? [String: String] }

            let numberFormatter = NumberFormatter()
            numberFormatter.maximumFractionDigits = 2
            numberFormatter.roundingMode = .halfUp

            if let dict = coins.filter({$0["symbol"]?.lowercased() == "nano"}).first {
                if let _price = dict["price_\(currency.paramValue)"] {
                    if let price = numberFormatter.number(from: _price) {
                        return price.doubleValue
                    } else {
                        Answers.logCustomEvent(withName: "Nano Price Pair unable to format", customAttributes: [:])
                        throw DecodableErrors.doubleCastError
                    }
                } else {
                    Answers.logCustomEvent(withName: "Nano Price Pair unable to get value for dict key", customAttributes: [:])
                    throw DecodableErrors.doubleCastError
                }

            } else {
                Answers.logCustomEvent(withName: "Nano Price Pair unable to get first coin", customAttributes: [:])
                throw DecodableErrors.doubleCastError
            }

//            guard
//                let dict = coins.filter({$0["symbol"]?.lowercased() == "nano"}).first,
//                let _price = dict["price_\(currency.paramValue)"],
//                let price = numberFormatter.number(from: _price)
//            else { throw DecodableErrors.doubleCastError }
//
//            return price.doubleValue
        } catch {
            Answers.logCustomEvent(withName: "Error in NanoPricePair.decode function", customAttributes: [:])

            throw DecodableErrors.priceError
        }
    }

}
