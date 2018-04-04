//
//  LocalCurrencyPair+NanoPricePair.swift
//  Nano
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Nano. All rights reserved.
//

// TODO: Refactor the error catching now that the error has been caught
struct LocalCurrencyPair {

    let currency: Currency

    func decode(fromData data: Data) throws -> Double {
        do {
            let coins = try JSONDecoder().decode([[String: String?]].self, from: data).compactMap { $0 as? [String: String] }

            if let dict = coins.first, let _price = dict["price_\(currency.paramValue)"] {
                guard let _double = Double(_price) else {
                    AnalyticsEvent.errorFormattingLocalCurrencyStringToDouble.track(customAttributes: [
                        "string_value": _price, "currency": currency.paramValue, "locale_description": currency.locale.description, "grouping_separator": currency.locale.groupingSeparator ?? ",", "decimal_separator": currency.locale.decimalSeparator ?? "."
                        ])

                    return 0.0
                }

                var double = _double
                return double.roundTo2f()
            } else {
                AnalyticsEvent.unableToGetLocalCurrencyPairBTCPrice.track(customAttributes: [
                    "currency": currency.paramValue, "locale_description": currency.locale.description, "grouping_separator": currency.locale.groupingSeparator ?? ",", "decimal_separator": currency.locale.decimalSeparator ?? "."
                    ])

                return 0.0
            }
        } catch {
            AnalyticsEvent.errorInLocalCurrencyDecodeFunction.track(customAttributes: [
                "currency": currency.paramValue, "locale_description": currency.locale.description, "grouping_separator": currency.locale.groupingSeparator ?? ",", "decimal_separator": currency.locale.decimalSeparator ?? "."
                ])

            return 0.0
        }
    }

}

struct NanoPricePair {

    let currency: Currency
    
    func decode(fromData data: Data) throws -> Double {
        do {
            let coins = try JSONDecoder().decode([[String: String?]].self, from: data).compactMap { $0 as? [String: String] }

            if let dict = coins.filter({$0["symbol"]?.lowercased() == "nano"}).first, let _price = dict["price_\(currency.paramValue)"] {
                guard let _double = Double(_price) else {
                    AnalyticsEvent.errorFormattingNanoStringToDouble.track(customAttributes: [
                        "string_value": _price, "currency": currency.paramValue, "locale_description": currency.locale.description, "grouping_separator": currency.locale.groupingSeparator ?? ",", "decimal_separator": currency.locale.decimalSeparator ?? "."
                        ])

                    return 0.0
                }

                var double = _double
                return double.roundTo2f()
            } else {
                AnalyticsEvent.unableToGetNanoPrice.track(customAttributes: [
                    "currency": currency.paramValue, "locale_description": currency.locale.description, "grouping_separator": currency.locale.groupingSeparator ?? ",", "decimal_separator": currency.locale.decimalSeparator ?? "."
                    ])

                return 0.0
            }
        } catch {
            AnalyticsEvent.errorInNanoDecodeFunction.track(customAttributes: [
                "currency": currency.paramValue, "locale_description": currency.locale.description, "grouping_separator": currency.locale.groupingSeparator ?? ",", "decimal_separator": currency.locale.decimalSeparator ?? "."
                ])

            return 0.0
        }
    }

}
