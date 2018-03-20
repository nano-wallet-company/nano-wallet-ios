//
//  RealmMigration.swift
//  Nano
//
//  Created by Zack Shapiro on 3/16/18.
//  Copyright © 2018 Nano. All rights reserved.
//

import Foundation
import RealmSwift


final class RealmMigration {

    static func migrate() {
        let currentSchemaVersion: UInt64 = 3
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            encryptionKey: UserService.getKeychainKeyID() as Data,
            readOnly: false,
            schemaVersion: currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                print("Migrating Realm from schema version \(oldSchemaVersion) to \(currentSchemaVersion)")

                migration.enumerateObjects(ofType: Credentials.className()) { oldObject, newObject in
                    print("oldSchemaVersion = \(oldSchemaVersion)")
                }

        }, deleteRealmIfMigrationNeeded: true)
    }

}
