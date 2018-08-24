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

    enum Endpoint: String {
        case coinMarketCap
        case currencyConverterAPI
    }
    
    enum APIResponse {
        case success(Double)
        case error(PricePair, Error?)
    }
    
    typealias PriceServiceCompletionBlock = (APIResponse)->()
    
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
        fetchLatestLocalCurrencyPrice(for: .btc)
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
    
    func fetchLatestLocalCurrencyPrice(for cryptoCurrency: Currency) {
        guard cryptoCurrency.isCryptoCurrency else {
            assertionFailure()
            return
        }
        
        let localCurrency = self.localCurrency.value
        fetchLatestPrice(for: cryptoCurrency, in: localCurrency, from: .coinMarketCap) { [weak self] apiResponse in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.handle(response: apiResponse, from: cryptoCurrency, to: localCurrency, endPoint: .coinMarketCap)
            
            switch apiResponse {
            case .success: break
            case .error: strongSelf.fetchLatestLocalCurrencyInRelationToUSD(for: cryptoCurrency)
            }
        }
    }
    
    fileprivate func fetchLatestLocalCurrencyInRelationToUSD(for cryptoCurrency: Currency) {
        guard cryptoCurrency.isCryptoCurrency else {
            assertionFailure()
            return
        }
        
        let localCurrency = self.localCurrency.value
        fetchLatestPrice(for: cryptoCurrency, in: .usd, from: .coinMarketCap) { [weak self] apiResponse in
            guard let strongSelf = self else {
                return
            }
            
            switch apiResponse {
            case let .success(priceInUSD):
                strongSelf.fetchLatestPrice(for: .usd, in: localCurrency, from: .currencyConverterAPI) { apiResponse in
                    switch apiResponse {
                    case let .success(USDInLocalCurrency):
                        strongSelf.handle(response: .success(priceInUSD * USDInLocalCurrency), from: cryptoCurrency, to: localCurrency, endPoint: .currencyConverterAPI)
                    case .error:
                        strongSelf.handle(response: apiResponse, from: cryptoCurrency, to: localCurrency, endPoint: .currencyConverterAPI)
                    }
                }
            case .error:
                strongSelf.handle(response: apiResponse, from: cryptoCurrency, to: .usd, endPoint: .coinMarketCap)
            }
        }
    }
    
    fileprivate func fetchLatestPrice(for currency: Currency,
                                      in otherCurrency: Currency,
                                      from endpoint: Endpoint,
                                      completion: @escaping PriceServiceCompletionBlock) {
        
        let pair = PricePair(from: currency, to: otherCurrency, endpoint: endpoint)
        guard let url = endpoint.conversionURL(from: currency, to: otherCurrency) else {
            completion(.error(pair, nil))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, let optionalPrice = try? pair.decode(fromData: data), let price = optionalPrice else {
                completion(.error(pair, error))
                return
            }
            completion(.success(price))
        }.resume()
    }
    
    fileprivate func handle(response: APIResponse,
                            from currency: Currency,
                            to otherCurrency: Currency,
                            endPoint: Endpoint) {
        switch response {
        case let .success(price):
            if otherCurrency == localCurrency.value {
                switch currency {
                case .btc: _lastBTCLocalCurrencyPrice.value = price
                case .nano: _lastNanoLocalCurrencyPrice.value = price
                default:
                    assertionFailure("Currency \(currency.paramValue) is unsupported.")
                    break
                }
            }
        case let .error(pair, error):
            var logParams = pair.logParams
            logParams["error_description"] = error?.localizedDescription ?? "n/a"
            endPoint.errorEvent.track(customAttributes: logParams)
        }
    }
}

extension PriceService.Endpoint {
    
    var errorEvent: AnalyticsEvent {
        switch self {
        case .coinMarketCap: return .errorGettingCMCPriceData
        case .currencyConverterAPI: return .errorGettingCCAPIPriceData
        }
    }
    
    func conversionURL(from: Currency, to: Currency) -> URL? {
        switch self {
        case .coinMarketCap:
            let baseURLString = "https://api.coinmarketcap.com/v1/ticker"
            switch from {
            case .btc: return URL(string: "\(baseURLString)/bitcoin/?convert=\(to.paramValue)")
            case .nano: return URL(string: "\(baseURLString)/nano/?convert=\(to.paramValue)")
            default:
                assertionFailure("This API does not support \(from.paramValue).")
                return nil
            }
        case .currencyConverterAPI:
            guard from.isCryptoCurrency == false && to.isCryptoCurrency == false else {
                assertionFailure("This API does not support cryptocurrency conversions.")
                return nil
            }
            let baseURLString = "https://free.currencyconverterapi.com/api/v5"
            return URL(string: "\(baseURLString)/convert?q=\(from.paramValue)_\(to.paramValue)&compact=y")
        }
    }
}
