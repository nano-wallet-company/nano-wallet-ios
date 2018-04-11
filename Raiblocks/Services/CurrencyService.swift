//
//  CurrencyService.swift
//  Nano
//
//  Created by Zack Shapiro on 2/5/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

import Foundation

import RealmSwift


final class CurrencyService {

    func store(currency: StorableCurrency, completion: (() -> Void)) {
        do {
            let realm = try Realm()

            try realm.write {
                realm.add(currency)

                completion()
            }

        } catch {

            AnalyticsEvent.trackCrash(error: .currencyStorageError) 

            completion()
        }
    }

    func localCurrency() -> Currency {
        do {
            let realm = try Realm()

            guard
                let currencySymbol = realm.objects(StorableCurrency.self).last?.symbol,
                let currency = Currency(rawValue: currencySymbol)
            else { return .usd }

            return currency
        } catch {
            return .usd
        }
    }

}
