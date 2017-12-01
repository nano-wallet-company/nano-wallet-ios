//
//  SendViewModel.swift
//  Raiblocks
//
//  Created by Zack Shapiro on 12/8/17.
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

import Foundation

import ReactiveSwift
import SwiftWebSocket


final class SendViewModel {

    let privateKeyData: Data
    let sendableNanoBalance: NSDecimalNumber
    let previousFrontierHash: String
    let socket: WebSocket
    let localCurrency: Currency

    let nanoAmount = MutableProperty<NSDecimalNumber>(0)
    let localCurrencyAmount = MutableProperty<NSDecimalNumber>(0)

    var maxAmountInUse: Bool = false

    let priceService = PriceService()

    private (set) var work: String?

    init(sendableNanoBalance: NSDecimalNumber, privateKeyData: Data, previousFrontierHash: String, socket: WebSocket, localCurrency: Currency) {
        self.sendableNanoBalance = sendableNanoBalance
        self.privateKeyData = privateKeyData
        self.previousFrontierHash = previousFrontierHash
        self.socket = socket
        self.localCurrency = localCurrency

        // Create work for the transaction
        DispatchQueue.global(qos: .background).async {
            RaiCore().createWork(previousHash: previousFrontierHash) { self.work = $0 }
        }

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

}
