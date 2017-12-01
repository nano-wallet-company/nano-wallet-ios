//
//  PriceService.swift
//  Raiblocks
//
//  Created by Zack Shapiro on 1/17/18.
//  Copyright © 2018 Zack Shapiro. All rights reserved.
//

import ReactiveSwift
import Result

import Crashlytics


final class PriceService {

    var localCurrency: Property<Currency>
    private let _localCurrency = MutableProperty<Currency>(Currency(rawValue: UserDefaults.standard.string(forKey: "localCurrency") ?? "") ?? .usd)

    var lastBTCTradePrice: Property<Double>
    private let _lastBTCTradePrice = MutableProperty<Double>(0)

    var lastBTCLocalCurrencyPrice: Property<Double>
    private let _lastBTCLocalCurrencyPrice = MutableProperty<Double>(0)

    var lastNanoLocalCurrencyPrice: Property<Double>
    private let _lastNanoLocalCurrencyPrice = MutableProperty<Double>(0)

    init() {
        self.localCurrency = Property<Currency>(_localCurrency)
        self.lastBTCTradePrice = Property<Double>(_lastBTCTradePrice)
        self.lastBTCLocalCurrencyPrice = Property<Double>(_lastBTCLocalCurrencyPrice)
        self.lastNanoLocalCurrencyPrice = Property<Double>(_lastNanoLocalCurrencyPrice)
    }

    func update(localCurrency currency: Currency) {
        self._localCurrency.value = currency
    }

    func fetchLatestPrices() {
        fetchLatestBTCPrice()
        fetchLatestBTCLocalCurrencyPrice()
    }

    private func fetchLatestBTCPrice() {
        guard let url = URL(string: "https://bitgrail.com/api/v1/BTC-XRB/ticker") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil else { return self.fetchPriceFromMercatox() }

            if let data = data, let xrb = try? JSONDecoder().decode(BGXRBPair.self, from: data), let lastBTCTradePrice = Double(xrb.xrbPair) {
                self._lastBTCTradePrice.value = lastBTCTradePrice
            } else {
                self.fetchPriceFromMercatox()
            }
        }.resume()
    }

    // Add Bitgrail and Kucoin

    private func fetchPriceFromMercatox() {
        guard let url = URL(string: "https://mercatox.com/public/json24") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil else {
                Answers.logCustomEvent(withName: "Error getting Mercatox price data")

                return self._lastBTCTradePrice.value = 0
            }

            if let data = data, let xrb = try? JSONDecoder().decode(MercXRBPair.self, from: data), let lastBTCTradePrice = Double(xrb.xrbPair.last) {
                self._lastBTCTradePrice.value = lastBTCTradePrice
            } else {
                Answers.logCustomEvent(withName: "Error decoding Mercatox price data")

                self._lastBTCTradePrice.value = 0
            }
        }.resume()
    }

    func fetchLatestBTCLocalCurrencyPrice() {
        guard let url = URL(string: "https://api.coinmarketcap.com/v1/ticker/?convert=\(localCurrency.value.paramValue)&limit=1") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil else {
                Answers.logCustomEvent(withName: "Error getting CoinMarketCap BTC price data")

                return self._lastBTCLocalCurrencyPrice.value = 0
            }

            let pair = LocalCurrencyPair(currency: self.localCurrency.value)

            if let data = data,let price = try? pair.decode(fromData: data) {
                self._lastBTCLocalCurrencyPrice.value = price
            } else {
                Answers.logCustomEvent(withName: "Error decoding CoinMarketCap BTC price data")

                self._lastBTCLocalCurrencyPrice.value = 0
            }
        }.resume()
    }

    func fetchLatestNanoLocalCurrencyPrice() {
        guard let url = URL(string: "https://api.coinmarketcap.com/v1/ticker/?convert=\(localCurrency.value.paramValue)&limit=50") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil else {
                Answers.logCustomEvent(withName: "Error getting CoinMarketCap Nano price data")

                return self._lastNanoLocalCurrencyPrice.value = 0
            }

            let pair = NanoPricePair(currency: self.localCurrency.value)

            if let data = data, let price = try? pair.decode(fromData: data) {
                self._lastNanoLocalCurrencyPrice.value = price
            } else {
                Answers.logCustomEvent(withName: "Error decoding CoinMarketCap Nano price data")

                self._lastNanoLocalCurrencyPrice.value = 0
            }
        }.resume()
    }

}
