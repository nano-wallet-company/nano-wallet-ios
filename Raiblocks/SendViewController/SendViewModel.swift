//
//  SendViewModel.swift
//  Nano
//
//  Created by Zack Shapiro on 12/8/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import Foundation

import ReactiveSwift
import SwiftWebSocket


final class SendViewModel {

    var sendableNanoBalance: NSDecimalNumber = 0
    var previousFrontierHash: String?

    let socket: WebSocket
    let sendSocket: WebSocket

    let localCurrency: Currency
    let groupingSeparator: String
    let decimalSeparator: String

    let nanoAmount = MutableProperty<NSDecimalNumber>(0)
    var maxAmountInUse: Bool = false

    let priceService = PriceService()

    private (set) var work: String?
    var workErrorClosure: (() -> Void)?

    var privateKeyData: Data {
        return credentials.privateKey
    }

    var address: Address {
        return credentials.address
    }

    let representative: Address

    private var credentials: Credentials {
        return UserService().fetchCredentials()!
    }

    init(homeSocket socket: WebSocket, representative: Address) {
        self.socket = socket
        self.representative = representative

        self.localCurrency = priceService.localCurrency.value
        self.groupingSeparator = localCurrency.locale.groupingSeparator ?? ","
        self.decimalSeparator = localCurrency.locale.decimalSeparator ?? "."
        // Default values are USD grouping/separator values

        guard
            let path = Bundle.main.path(forResource: "Common", ofType: "plist"),
            let root = NSDictionary(contentsOfFile: path) as? [String: String],
            let urlString = root["socketServerURL"]
        else { fatalError("Could not load socket server URL") }

        self.sendSocket = WebSocket(urlString)

        sendSocket.event.message = { message in
//            print(message)
            guard let str = message as? String, let data = str.asUTF8Data() else { return }

            if let accountInfo = genericDecoder(decodable: AccountInfo.self, from: data) {
                return self.handle(accountInfo: accountInfo)
            }
        }

        sendSocket.open()

        priceService.fetchLatestBTCLocalCurrencyPrice()
        priceService.fetchLatestNanoLocalCurrencyPrice()
    }

    /// Turn the remaining balance into a hex
    /// `balance` sent in should be raw value
    /// e.g. 9993120000000000000000000000000
    func hexify(balance num: NSDecimalNumber) -> String {
        var result = num
        var hex = ""
        let index: String.Index = hex.startIndex

        // result > 0
        while result.compare(0) == .orderedDescending {
            let radix: NSDecimalNumber = 16

            let handler = NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
            let quotient = result.dividing(by: radix, withBehavior: handler)
            let subtractAmount = quotient.multiplying(by: radix)

            let remainder = result.subtracting(subtractAmount).intValue

            switch remainder {
            case 0...9: hex.insert(String(remainder).first!, at: index)
            case 10:    hex.insert("A", at: index)
            case 11:    hex.insert("B", at: index)
            case 12:    hex.insert("C", at: index)
            case 13:    hex.insert("D", at: index)
            case 14:    hex.insert("E", at: index)
            case 15:    hex.insert("F", at: index)

            default:
                fatalError("Hexing problem")
            }

            result = quotient
        }

        return hex
    }

    func checkAndOpenSocket() {
        if socket.readyState == .closed { socket.open() }
    }

    private func handle(accountInfo: AccountInfo) {
        self.previousFrontierHash = accountInfo.frontier
        self.sendableNanoBalance = accountInfo.transactableBalance

        // Create work for the transaction
        DispatchQueue.global(qos: .background).async {
            RaiCore().createWork(previousHash: accountInfo.frontier) { createdWork in
                if let createdWork = createdWork {
                    self.work = createdWork
                } else {
                    AnalyticsEvent.errorGeneratingWorkForSending.track()

                    DispatchQueue.main.async {
                        self.workErrorClosure?()
                    }
                }
            }
        }
    }

}
