//
//  XRBPair.swift
//  Nano
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Nano. All rights reserved.
//

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

            guard
                let dict = coins.first,
                let _price = dict["price_\(currency.paramValue)"],
                let price = numberFormatter.number(from: _price)
            else { throw DecodableErrors.doubleCastError }

            return price.doubleValue
        } catch {
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

            guard
                let dict = coins.filter({$0["symbol"]?.lowercased() == "nano" || $0["symbol"]?.lowercased() == "xrb" }).first,
                let _price = dict["price_\(currency.paramValue)"],
                let price = numberFormatter.number(from: _price)
            else { throw DecodableErrors.doubleCastError }

            return price.doubleValue
        } catch {
            throw DecodableErrors.priceError
        }
    }

}
