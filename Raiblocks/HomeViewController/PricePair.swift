//
//  PricePair.swift
//  Nano
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

struct PricePair {
    let from: Currency
    let to: Currency
    let endpoint: PriceService.Endpoint

    func decode(fromData data: Data) throws -> Double? {
        do {
            switch endpoint {
            case .coinMarketCap:
                let coins = try JSONDecoder().decode([[String: String?]].self, from: data).compactMap { $0 as? [String: String] }

                if let dict = coins.first, let price = dict["price_\(to.paramValue)"], var priceInDouble = Double(price) {
                    return priceInDouble.roundTo2f()
                }
                return nil
            case .currencyConverterAPI:
                let currencies = try JSONDecoder().decode([String: [String: Double?]].self, from: data).compactMap { $1 as? [String: Double] }
                if let currency = currencies.first, var price = currency["val"] {
                    return price.roundTo2f()
                }
                return nil
            }
        } catch {
            return nil
        }
    }
}

extension PricePair {
    var logParams: [String: String] {
        let fromNumberFormatter = from.numberFormatter
        let toNumberFormatter = to.numberFormatter
        return [
            "from_currency": from.paramValue,
            "from_locale_description": from.locale.description,
            "from_grouping_separator": fromNumberFormatter.groupingSeparator,
            "from_decimal_separator": fromNumberFormatter.decimalSeparator,
            
            "to_currency": to.paramValue,
            "to_locale_description": to.locale.description,
            "to_grouping_separator": toNumberFormatter.groupingSeparator,
            "to_decimal_separator": toNumberFormatter.decimalSeparator,
            
            "endpoint": endpoint.rawValue
        ]
    }
}
