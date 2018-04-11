//
//  ExchangePairs.swift
//  Nano
//
//  Created by Zack Shapiro on 2/7/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

// MARK: - Protocol

protocol ExchangePair: Decodable {
    var last: Double { get }
}

// MARK: - Enum

enum Exchange: String {

    case binance, okex, kucoin

    var url: URL? {
        switch self {
        case .binance: return URL(string: "https://api.binance.com/api/v1/ticker/24hr?symbol=NANOBTC")
        case .okex: return URL(string: "https://www.okex.com/api/v1/ticker.do?symbol=nano_btc")
        case .kucoin: return URL(string: "https://api.kucoin.com/v1/XRB-BTC/open/tick")
        }
    }

}

// MARK: - Decodable Types

struct BinanceNanoBTCPair: ExchangePair {

    private let lastPrice: String

    // TODO: Refactor Decimal (for all of these)
    var last: Double {
        return Double(lastPrice) ?? 0
    }

}


struct OkExNanoBTCPair: ExchangePair {

    let ticker: [String: String]

    var last: Double {
        guard let last = ticker["last"] else { return 0 }

        return Double(last) ?? 0
    }

}


struct KucoinNanoBTCPair: ExchangePair {

    private let data: KucoinData

    struct KucoinData: Decodable {
        let lastDealPrice: Double
    }

    var last: Double {
        return data.lastDealPrice
    }
}
