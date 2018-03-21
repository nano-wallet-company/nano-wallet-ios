//
//  Credentials.swift
//  Nano
//
//  Created by Zack Shapiro on 12/6/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import Foundation

import RealmSwift


final class Credentials: Object {

    @objc dynamic var id: String = "0"
    @objc dynamic var seed: String = ""
    @objc dynamic var privateKey: Data = Data()

    @objc dynamic var hasCompletedLegalAgreements: Bool = false
    @objc dynamic var socketUUID: String?

    override class func primaryKey() -> String? {
        return "id"
    }

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

}
