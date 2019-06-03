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

    private(set) var sendableNanoBalance: NSDecimalNumber
    var previousFrontierHash: String?

    let socket: WebSocket
    let sendSocket: WebSocket

    let localCurrency: Currency
    let groupingSeparator: String
    let decimalSeparator: String

    let nanoAmount = MutableProperty<NSDecimalNumber>(0)
    var maxAmountInUse: Bool = false

    let headBlockIsValid = MutableProperty<Bool>(false)

    let priceService = PriceService()

    private (set) var work: String?
    var workErrorClosure: (() -> Void)?

    var privateKeyData: Data {
        return credentials.privateKey
    }

    var address: Address {
        return credentials.address
    }

    private (set) var toAddress: Address?
    var representative: Address?

    private var credentials: Credentials {
        return UserService().fetchCredentials()!
    }

    private var updateWithLegacyBlock: Bool = false
    private var accountInfo: AccountInfo?

    private var headBlock: StateBlock? {
        didSet {
            guard
                let headBlock = headBlock,
                let representative = headBlock.representativeAddress,
                let previous = previousFrontierHash,
                let string = headBlock.asStringifiedDictionary,
                let hash = RaiCore().hashBlock(string),
                hash == previous
            else {
                AnalyticsEvent.unableToValidateHeadBlock.track()

                return
            }

            self.sendableNanoBalance = headBlock.transactableBalance
            self.representative = representative
            self.headBlockIsValid.value = true
        }
    }

    init(homeSocket socket: WebSocket, toAddress: Address? = nil, initialSendableBalance: NSDecimalNumber) {
        self.socket = socket
        self.toAddress = toAddress
        self.sendableNanoBalance = initialSendableBalance

        self.localCurrency = priceService.localCurrency.value
        self.groupingSeparator = localCurrency.locale.groupingSeparator ?? ","
        self.decimalSeparator = localCurrency.locale.decimalSeparator ?? "."
        // Default values are USD grouping/separator values

        let urlString = UserService.socketServerURL
        self.sendSocket = WebSocket(urlString)

        sendSocket.event.message = { message in
//            print(message)
            guard let str = message as? String, let data = str.asUTF8Data() else { return }

            if let accountInfo = genericDecoder(decodable: AccountInfo.self, from: data) {
                return self.handle(accountInfo: accountInfo)
            }

            if let headBlock = genericDecoder(decodable: StateBlockContainer.self, from: data) {
                if let _ = headBlock.block as? LegacyBlock {
                    guard let accountInfo = self.accountInfo else { return }

                    self.sendableNanoBalance = accountInfo.transactableBalance
                    self.headBlockIsValid.value = true
                } else {
                    self.headBlock = (headBlock.block as! StateBlock)
                }
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

//    /// Only use this function for Send transactions
//    /// its really only important for displaying an accurate amount in the case of a mitm
//    func verifySignature(stateBlock block: StateBlock) -> Bool {
//        var blockTypes: [BlockType] = [.open(sendBlockHash: block.link), .receive(sendBlockHash: block.link)]
//
//        if let toAddress = block.toAddress {
//            blockTypes.append(.send(destinationAddress: toAddress))
//        }
//
//        for blockType in blockTypes {
//            let ep = Endpoint.createStateBlock(
//                type: blockType,
//                previous: block.previous,
//                remainingBalance: block.transactableBalance.stringValue,
//                work: block.work,
//                fromAccount: block.accountAddress,
//                representative: block.representativeAddress!
//            )
//
//            if ep.stringify()!.contains(block.signature) {
//                return true
//            }
//        }
//
//        return false
//    }

    func checkAndOpenSocket() {
        if socket.readyState == .closed { socket.open() }
    }

    private func handle(accountInfo: AccountInfo) {
        self.accountInfo = accountInfo
        self.previousFrontierHash = accountInfo.frontier
        self.representative = accountInfo.representativeAddress

        // Get head block
        sendSocket.send(endpoint: .getBlock(withHash: accountInfo.frontier))

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
