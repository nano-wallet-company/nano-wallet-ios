//
//  Credentials.swift
//  Raiblocks
//
//  Created by Zack Shapiro on 12/6/17.
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

import Foundation

import RealmSwift


final class Credentials: Object {

    @objc dynamic var seed: String = ""
    @objc dynamic var privateKey: Data = Data()

    convenience init?(seed: Data) {
        guard seed.count == 32 else { return nil }

        self.init()

        let core = RaiCore()
        self.seed = core.seedOrKey(toString: seed)
        self.privateKey = core.createPrivateKey(seed, at: 0)
    }

    convenience init?(seedString seed: String) {
        guard seed.count == 64 else { return nil }

        self.init()

        self.seed = seed
        self.privateKey = RaiCore().privateKey(forSeed: seed, at: 0)
    }

    // MARK: - Computed Variables

    var privateKeyString: String {
        return RaiCore().seedOrKey(toString: privateKey)
    }

    var publicKey: String {
        let core = RaiCore()
        let publicKey = core.createPublicKey(privateKey)

        return core.seedOrKey(toString: publicKey)
    }

    var address: Address {
        let core = RaiCore()
        let publicKey = core.createPublicKey(privateKey)

        return Address(core.createAddress(fromPublicKey: publicKey))!
    }

    // MARK: - Functions

    // TODO: remove this
    static func legacyLogOut() {
        let defaults = UserDefaults.standard

        for val in ["seed", "pkd", "publicKey", "address", "localCurrency"] {
            defaults.set(nil, forKey: val)
        }
    }

}
