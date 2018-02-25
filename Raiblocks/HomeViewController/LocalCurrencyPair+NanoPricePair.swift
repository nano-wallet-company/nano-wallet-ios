//
//  LocalCurrencyPair+NanoPricePair.swift
//  Nano
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import Crashlytics


struct LocalCurrencyPair {

    let currency: Currency

    func decode(fromData data: Data) throws -> Double {
        do {
            let coins = try JSONDecoder().decode([[String: String?]].self, from: data)
                .flatMap { $0 as? [String: String] }


            if let dict = coins.first, let _price = dict["price_\(currency.paramValue)"] {
                guard let _double = Double(_price) else {
                    Answers.logCustomEvent(withName: "Error formatting Local Currency String to Double", customAttributes: ["string_value": _price, "currency": currency.paramValue, "locale_description": Locale.current.description, "grouping_separator": Locale.current.groupingSeparator ?? ",", "decimal_separator": Locale.current.decimalSeparator ?? "."])

                    return 0.0
                }

                var double = _double
                return double.roundTo2f()
            } else {
                Answers.logCustomEvent(withName: "Local Currency Pair Error: unable to get Bitcoin price", customAttributes: ["currency": currency.paramValue, "locale_description": Locale.current.description, "grouping_separator": Locale.current.groupingSeparator ?? ",", "decimal_separator": Locale.current.decimalSeparator ?? "."])

                return 0.0
            }
        } catch {
            Answers.logCustomEvent(withName: "Error in LocalCurrencyPair.decode function", customAttributes: ["currency": currency.paramValue, "locale_description": Locale.current.description, "grouping_separator": Locale.current.groupingSeparator ?? ",", "decimal_separator": Locale.current.decimalSeparator ?? "."])

            return 0.0
        }
    }

}

struct NanoPricePair {

    let currency: Currency
    
    func decode(fromData data: Data) throws -> Double {
        do {
            let coins = try JSONDecoder().decode([[String: String?]].self, from: data)
                .flatMap { $0 as? [String: String] }

            if let dict = coins.filter({$0["symbol"]?.lowercased() == "nano"}).first, let _price = dict["price_\(currency.paramValue)"] {
                guard let _double = Double(_price) else {
                    Answers.logCustomEvent(withName: "Error formatting Nano Price Pair String to Double", customAttributes: ["string_value": _price, "currency": currency.paramValue, "locale_description": Locale.current.description, "grouping_separator": Locale.current.groupingSeparator ?? ",", "decimal_separator": Locale.current.decimalSeparator ?? "."])

                    return 0.0
                }

                var double = _double
                return double.roundTo2f()
            } else {
                Answers.logCustomEvent(withName: "Nano Price Pair Error: unable to get price", customAttributes: ["currency": currency.paramValue, "locale_description": Locale.current.description, "grouping_separator": Locale.current.groupingSeparator ?? ",", "decimal_separator": Locale.current.decimalSeparator ?? "."])

                return 0.0
            }
        } catch {
            Answers.logCustomEvent(withName: "Error in NanoPricePair.decode function", customAttributes: ["currency": currency.paramValue, "locale_description": Locale.current.description, "grouping_separator": Locale.current.groupingSeparator ?? ",", "decimal_separator": Locale.current.decimalSeparator ?? "."])

            return 0.0
        }
    }

}
