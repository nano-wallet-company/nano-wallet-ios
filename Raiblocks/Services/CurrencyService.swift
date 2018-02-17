//
//  CurrencyService.swift
//  Nano
//
//  Created by Zack Shapiro on 2/5/18.
//  Copyright © 2018 Nano. All rights reserved.
//

import Foundation

import Crashlytics
import RealmSwift


final class CurrencyService {

    func store(currency: StorableCurrency, completion: (() -> Void)) {
        do {
            let config = Realm.Configuration(encryptionKey: UserService.getKeychainKeyID() as Data)
            let realm = try Realm(configuration: config)

            try realm.write {
                realm.add(currency)

                completion()
            }

        } catch {
            Crashlytics.sharedInstance().recordError(NanoWalletError.currencyStorageError)

            completion()
        }
    }

    func localCurrency() -> Currency {
        do {
            let config = Realm.Configuration(encryptionKey: UserService.getKeychainKeyID() as Data)
            let realm = try Realm(configuration: config)

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
