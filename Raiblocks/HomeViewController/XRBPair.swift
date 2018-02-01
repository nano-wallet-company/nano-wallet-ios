//
//  XRBPair.swift
//  Nano
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Nano. All rights reserved.
//

// TODO: Add Kucoin pair
// https://kucoinapidocs.docs.apiary.io/#reference/0/currencies-plugin/list-exchange-rate-of-coins(open)

struct BGXRBPair: Decodable {

    let response: Response

    var xrbPair: String {
        return response.last
    }

    struct Response: Decodable {
        let last: String
    }

}


struct MercXRBPair: Decodable {

    let pairs: [String: Pair]

    var xrbPair: Pair {
        return pairs.filter { $0.key == "XRB_BTC" }.first!.value
    }

    struct Pair: Decodable {
        let last: String
    }

}

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
