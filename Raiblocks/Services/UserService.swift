//
//  UserService.swift
//  Nano
//
//  Created by Zack Shapiro on 1/23/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

import RealmSwift


final class UserService {

    static var socketServerURL: String {
        return "wss://light.nano.org"
    }
    
    private static var keychainID: String {
        return "io.Realm.NanoWalletiOS"
    }
    
    static func getKeychainKeyID() -> NSData {
        // First check in the keychain for an existing key
        var query: [NSString: AnyObject] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainID as AnyObject,
            kSecAttrKeySizeInBits: 512 as AnyObject,
            kSecReturnData: true as AnyObject
        ]

        // To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
        // See also: http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
        var dataTypeRef: AnyObject?
        var status = withUnsafeMutablePointer(to: &dataTypeRef) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }
        if status == errSecSuccess {
            return dataTypeRef as! NSData
        }

        // No pre-existing key from this application, so generate a new one
        let keyData = NSMutableData(length: 64)!
        let result = SecRandomCopyBytes(kSecRandomDefault, 64, keyData.mutableBytes.bindMemory(to: UInt8.self, capacity: 64))
        assert(result == 0, "Failed to get random bytes")

        // Store the key in the keychain
        query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainID as AnyObject,
            kSecAttrKeySizeInBits: 512 as AnyObject,
            kSecValueData: keyData,
            kSecAttrIsPermanent: true as AnyObject
        ]

        status = SecItemAdd(query as CFDictionary, nil)
        assert(status == errSecSuccess, "Failed to insert the new key in the keychain")

        return keyData
    }

    func store(credentials: Credentials, completion: (() -> Void)? = nil) {
        do {
            let realm = try Realm()

            try realm.write {
                realm.add(credentials)

                completion?()
            }
        } catch {
           AnalyticsEvent.trackCrash(error: .credentialStorageError)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LogOut"), object: nil)
        }
    }

    func fetchCredentials() -> Credentials? {
        do {
            let realm = try Realm()

            return realm.objects(Credentials.self).first

        } catch {
            return nil
        }
    }

    /// Used for updating with socketUUID
    func update(credentials: Credentials, uuid: String? = nil) {
        do {
            let realm = try Realm()

            try realm.write {
                if let uuid = uuid {
                    credentials.socketUUID = uuid
                }
                realm.add(credentials, update: true)
                realm.refresh()
            }
        } catch {
            AnalyticsEvent.trackCrash(error: .unableToUpdateCredentialsWithUUID)
            return
        }
    }

    func updateLegal() {
        guard let credentials = fetchCredentials() else { return }

        do {
            let realm = try Realm()

            try realm.write {
                credentials.hasCompletedLegalAgreements = true
                realm.add(credentials, update: true)

                realm.refresh()
            }
        } catch {
            AnalyticsEvent.trackCrash(error: .unableToUpdateCredentialsWithLegalAgreement)

            return
        }
    }

    func updateUserAgreesToTracking(_ val: Bool) {
        guard let credentials = fetchCredentials() else { return }

        do {
            let realm = try Realm()

            try realm.write {
                credentials.hasAnsweredAnalyticsQuestion = true
                credentials.hasAgreedToTracking = val

                realm.add(credentials, update: true)
                realm.refresh()
            }
        } catch {
            AnalyticsEvent.trackCrash(error: .unableToUpdateCredentialsWithAnalyticsAgreement)

            return
        }
    }

    func currentUserSeed() -> String? {
        do {
            let realm = try Realm()

            return realm.objects(Credentials.self).first?.seed
        } catch {
            AnalyticsEvent.trackCrash(error: .unableToGetCurrentUserSeed)

            return nil
        }
    }

    static func logOut() {
        do {
            let realm = try Realm()

            try realm.write {
                realm.deleteAll()
            }
        } catch {
           AnalyticsEvent.trackCrash(error: .logOutError)
        }
    }

}
