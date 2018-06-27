//
//  PriceService.swift
//  Nano
//
//  Created by Zack Shapiro on 1/17/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

import ReactiveSwift
import Result


final class PriceService {

    var localCurrency: Property<Currency>
    private let _localCurrency = MutableProperty<Currency>(CurrencyService().localCurrency())

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
        fetchLatestPrice(exchange: .binance, decodable: BinanceNanoBTCPair.self)
        fetchLatestBTCLocalCurrencyPrice()
    }

    func fetchLatestPrice<T: ExchangePair>(exchange: Exchange, decodable: T.Type) {
        guard let url = exchange.url else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else {
                AnalyticsEvent.errorGettingExchangePriceData.track(customAttributes: ["name": exchange.rawValue, "location": "error case", "response": response?.description ?? ""])

                switch exchange {
                case .binance: return self.fetchLatestPrice(exchange: .okex, decodable: OkExNanoBTCPair.self)
                case .okex: return self.fetchLatestPrice(exchange: .kucoin, decodable: KucoinNanoBTCPair.self)
                case .kucoin: return self._lastBTCTradePrice.value = 0
                }
            }

            if let data = data, let json = try? JSONDecoder().decode(decodable, from: data) {
                self._lastBTCTradePrice.value = json.last
            } else {
                AnalyticsEvent.errorGettingExchangePriceData.track(customAttributes: ["name": exchange.rawValue, "location": "unable to decode data", "response": response?.description ?? ""])

                switch exchange {
                case .binance: return self.fetchLatestPrice(exchange: .okex, decodable: OkExNanoBTCPair.self)
                case .okex: return self.fetchLatestPrice(exchange: .kucoin, decodable: KucoinNanoBTCPair.self)
                case .kucoin: return self._lastBTCTradePrice.value = 0
                }
            }
        }.resume()
    }

    func fetchLatestBTCLocalCurrencyPrice() {
        guard let url = URL(string: "https://api.coinmarketcap.com/v1/ticker/?convert=\(localCurrency.value.paramValue)&limit=1") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else {
                AnalyticsEvent.errorGettingCMCBTCPriceData.track(customAttributes: ["error_description": error?.localizedDescription ?? ""])

                return self._lastBTCLocalCurrencyPrice.value = 0
            }

            let pair = LocalCurrencyPair(currency: self.localCurrency.value)
            if let data = data, let price = try? pair.decode(fromData: data) {
                self._lastBTCLocalCurrencyPrice.value = price
            } else {
                AnalyticsEvent.errorDecodingCMCBTCPriceData.track(customAttributes: ["error_description": "No description", "url": url.absoluteString])

                self._lastBTCLocalCurrencyPrice.value = 0
            }
        }.resume()
    }

    func fetchLatestNanoLocalCurrencyPrice() {
        guard let url = URL(string: "https://api.coinmarketcap.com/v1/ticker/?convert=\(localCurrency.value.paramValue)&limit=50") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil else {
                AnalyticsEvent.errorGettingCMCNanoPriceData.track(customAttributes: ["error_description": error?.localizedDescription ?? ""])

                return self._lastNanoLocalCurrencyPrice.value = 0
            }

            let pair = NanoPricePair(currency: self.localCurrency.value)
            if let data = data, let price = try? pair.decode(fromData: data) {
                self._lastNanoLocalCurrencyPrice.value = price
            } else {
                AnalyticsEvent.errorDecodingCMCNanoPriceData.track(customAttributes: ["url": url.absoluteString, "event": "data unwrap failed", "currency": pair.currency.paramValue])

                self._lastNanoLocalCurrencyPrice.value = 0
            }
        }.resume()
    }

}
