//
//  Currency.swift
//  Nano
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import RealmSwift


final class StorableCurrency: Object {
    @objc dynamic var symbol: String = ""

    convenience init?(string: String) {
        guard let _ = Currency(rawValue: string) else { return nil }

        self.init()

        self.symbol = string
    }
}


enum Currency: String {
    case aud
    case brl
    case cad
    case chf
    case clp
    case cny
    case czk
    case dkk
    case eur
    case gbp
    case hkd
    case huf
    case idr
    case ils
    case inr
    case jpy
    case krw
    case mxn
    case myr
    case nok
    case nzd
    case php
    case pkr
    case pln
    case rub
    case sek
    case sgd
    case thb
    case _try
    case twd
    case vef
    case zar
    case usd
    
    // Cryptocurrencies
    case btc
    case nano

    // Unicode Nano symbol would be dope
    var mark: String {
        switch self {
        case .btc: return "₿"
        case .nano: return "NANO"
        default: return locale.currencySymbol!
        }
    }

    var currencyCode: String {
        return rawValue.uppercased()
    }

    private var localIdentifier: String {
        // https://gist.github.com/ncreated/9934896

        switch self {
        case .aud: return "en_US"
        case .brl: return "en_BR"
        case .cad: return "en_US" // uses $
        case .chf: return "en_CH"
        case .clp: return "en_US" // uses $
        case .cny: return "yue_Hans_CN"
        case .czk: return "cs_CZ"
        case .dkk: return "en_DK"
        case .eur: return "en_EU"
        case .gbp: return "en_GB"
        case .hkd: return "zh_Hans_HK"
        case .huf: return "hu_HU"
        case .idr: return "id_ID"
        case .ils: return "en_il"
        case .inr: return "en_IN"
        case .jpy: return "ja_JP"
        case .krw: return "ko_KR"
        case .mxn: return "es_MX" // uses $
        case .myr: return "ta_MY"
        case .nok: return "nn_NO" // fo_FO or nn_NO
        case .nzd: return "en_NZ" // uses $
        case .php: return "fil_PH"
        case .pkr: return "en_MU"
        case .pln: return "pl_PL"
        case .rub: return "ru_RU"
        case .sek: return "en_SE"
        case .sgd: return "en_US" // uses $
        case .thb: return "th_TH"
        case ._try: return "tr_TR"
        case .twd: return "en_TW"
        case .vef: return "es_VE"
        case .zar: return "pt_BR"
        case .usd: return "en_US"
        
        // Cryptocurrencies
        case .btc, .nano: return "en_US"
        }
    }

    static var allFiatCurrencies: [Currency] {
        return [.aud, .brl, .cad, .chf, .clp, .cny, .czk, .dkk, .eur, .gbp, .hkd, .huf, .idr, .ils, .inr, .jpy, .krw, .mxn, .myr, .nok, .nzd, .php, .pkr, .pln, .rub, .sek, .sgd, .thb, ._try, .twd, .vef, .zar, .usd]
    }

    var paramValue: String {
        switch self {
        case ._try: return "try"
        default: return self.rawValue
        }
    }

    var locale: Locale {
        return Locale(identifier: localIdentifier)
    }

    var name: String {
        switch self {
        case .aud: return "Australian Dollar"
        case .brl: return "Brazilian Real"
        case .cad: return "Canadian Dollar"
        case .chf: return "Swiss Franc"
        case .clp: return "Chilean Peso"
        case .cny: return "Chinese Yuan"
        case .czk: return "Czech Koruna"
        case .dkk: return "Danish Krone"
        case .eur: return "Euro"
        case .gbp: return "Great British Pound"
        case .hkd: return "Hong Kong Dollar"
        case .huf: return "Hungarian Forint"
        case .idr: return "Indonesian Rupiah"
        case .ils: return "Israeli Shekel"
        case .inr: return "Indian Rupee"
        case .jpy: return "Japanese Yen"
        case .krw: return "South Korean Won"
        case .mxn: return "Mexican Peso"
        case .myr: return "Malaysian Ringgit"
        case .nok: return "Norwegian Krone"
        case .nzd: return "New Zealand Dollar"
        case .php: return "Philippine Peso"
        case .pkr: return "Pakistani Rupee"
        case .pln: return "Polish Zloty"
        case .rub: return "Russian Ruble"
        case .sek: return "Swedish Krona"
        case .sgd: return "Singapore Dollar"
        case .thb: return "Thai Baht"
        case ._try: return "Turkish Lira"
        case .twd: return "Taiwan New Dollar"
        case .vef: return "Venezuelan Bolivar"
        case .zar: return "South African Rand"
        case .usd: return "US Dollar"
            
        // Cryptocurrencies
        case .btc: return "Bitcoin"
        case .nano: return "Nano"
        }
    }

    var nameWithMark: String {
        switch self {
        case .btc: return "Bitcoin"
        case .nano: return "Nano"
        default: return mark + " " + name
        }
    }

    var numberFormatter: NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        numberFormatter.maximumFractionDigits = 20

        if isCryptoCurrency {
            numberFormatter.numberStyle = .decimal
        } else {
            numberFormatter.numberStyle = .currency
        }

        return numberFormatter
    }

    var isCryptoCurrency: Bool {
        switch self {
        case .btc, .nano: return true
        default: return false
        }
    }
}
