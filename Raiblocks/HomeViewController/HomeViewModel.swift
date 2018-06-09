//
//  HomeViewModel.swift
//  Nano
//
//  Created by Zack Shapiro on 12/20/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import ReactiveSwift
import RealmSwift
import Result
import SwiftWebSocket


final class HomeViewModel {

    let socket: WebSocket

    let userService = UserService()
    private let priceService = PriceService()

    var credentials: Credentials {
        guard let credentials = userService.fetchCredentials() else {
            AnalyticsEvent.missingCredentials.track()

            fatalError("There should always be a seed")
        }

        return credentials
    }

    var privateKey: Data {
        return credentials.privateKey
    }

    var hasCompletedLegalAgreements: Bool {
        return credentials.hasCompletedLegalAgreements
    }

    var hasCompletedAnalyticsOptIn: Bool {
        return credentials.hasAnsweredAnalyticsQuestion
    }

    var address: Address {
        return credentials.address
    }

    private let _frontierBlockHash = MutableProperty<String?>(nil)
    var frontierBlockHash: ReactiveSwift.Property<String?>

    var initialLoadComplete: Bool = false
    let transactions = MutableProperty<[NanoTransaction]>([])

    let isCurrentlySyncing = MutableProperty<Bool>(false)
    let isCurrentlySending = MutableProperty<Bool>(false)

    let _hasNetworkConnection = MutableProperty<Bool>(false)
    var hasNetworkConnection: ReactiveSwift.Property<Bool>

    let addressIsOnNetwork = MutableProperty<Bool>(false)

    // Will refactor, this property is used in the case where the user opens a new account and we need to set the rep
    // I didn't want to call .accountSubscribe since we're already subscribed
    // This value will be nil any other time the user opens the app, the app will just use the computed property `representative` below
    // since it will be able to get a rep value from .accountSubscribe
    // The "temporary" name connotes its value in the app, not its value on the network
    var temporaryRepresentative: Address? = nil

    var representative: Address? {
        return accountSubscribe?.representativeAddress
    }

    private var accountInfo: AccountInfo?
    private var accountHistory: AccountHistory?

    private var accountSubscribe: AccountSubscribe?

    private let _transactableAccountBalance = MutableProperty<NSDecimalNumber>(0)
    var transactableAccountBalance: ReactiveSwift.Property<NSDecimalNumber>

    let lastBlockCount = MutableProperty<Int>(0)

    private var pendingBlocks: [String: PendingHistoryItem] = [:]

    private var disposable = SerialDisposable()
    private var _pendingBlocks = SignalProducer<[String: PendingHistoryItem], NoError>([])

    var localCurrency: ReactiveSwift.Property<Currency> {
        return priceService.localCurrency
    }

    var lastBTCTradePrice: ReactiveSwift.Property<Double> {
        return priceService.lastBTCTradePrice
    }

    var lastBTCLocalCurrencyPrice: ReactiveSwift.Property<Double> {
        return priceService.lastBTCLocalCurrencyPrice
    }

    // This is gross, will refactor, just used to set when we get a new one
    var previousFrontierHash: String? {
        get {
            if let value = self._previousFrontierHash.value {
                return value
            } else if let _ = accountSubscribe?.frontierBlockHash {
                return accountSubscribe?.frontierBlockHash
            } else {
                return nil
            }
        }
    }

    private let _previousFrontierHash = MutableProperty<String?>(nil)

    init() {
        guard
            let path = Bundle.main.path(forResource: "Common", ofType: "plist"),
            let root = NSDictionary(contentsOfFile: path) as? [String: String],
            let urlString = root["socketServerURL"]
        else { fatalError("Could not load socket server URL") }

        self.frontierBlockHash = ReactiveSwift.Property<String?>(_frontierBlockHash)
        self.transactableAccountBalance = ReactiveSwift.Property<NSDecimalNumber>(_transactableAccountBalance)
        self.hasNetworkConnection = ReactiveSwift.Property<Bool>(_hasNetworkConnection)

        // MARK: - Socket Setup

        self.socket = WebSocket(urlString)

        NotificationCenter.default.addObserver(self, selector: #selector(appWasReopened(_:)), name: Notification.Name(rawValue: "ReestablishConnection"), object: nil)

        socket.event.open = {
//            print("socket opened")
            self._hasNetworkConnection.value = true

            self.socket.sendMultiple(endpoints: [
                .accountSubscribe(uuid: self.userService.fetchCredentials()?.socketUUID, address: self.address),
                .accountCheck(address: self.address),
            ])
        }

        socket.event.close = { code, reason, clean in
            AnalyticsEvent.socketClosedHome.track(customAttributes: ["code": code, "reason": reason])

            self._hasNetworkConnection.value = false
            // print("CONNECTION WAS CLOSED")
        }

        socket.event.error = { error in
            AnalyticsEvent.socketErrorHome.track(customAttributes: ["error": error.localizedDescription])
            // print("error \(error)")
        }

        self.socket.event.message = { message in
//            print(message) // Uncomment for development
//            print("")
            guard let str = message as? String, let data = str.asUTF8Data() else { return }

            if let accountCheck = genericDecoder(decodable: AccountCheck.self, from: data) {
                return self.handle(accountCheck: accountCheck) {
                    self.socket.send(endpoint: .accountPending(address: self.address))
                }
            }

            if let subscriptionBlock = genericDecoder(decodable: SubscriptionTransaction.self, from: data) {
                // To prevent coming back to the app and receiving multiple subscription txns you may have gotten when you were away. Will improve later.
                guard !self.isCurrentlySending.value else { return }

                return self.handle(subscriptionBlock: subscriptionBlock) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.socket.send(endpoint: .accountBlockCount(address: self.address))
                    }
                }
            }

            if let accountSubscribe = genericDecoder(decodable: AccountSubscribe.self, from: data) {
                return self.handle(accountSubscribe: accountSubscribe) {
                    self.socket.send(endpoint: Endpoint.accountHistory(address: self.address, count: self.lastBlockCount.value))
                }
            }

            if let accountHistory = genericDecoder(decodable: AccountHistory.self, from: data) {
                return self.handle(accountHistory: accountHistory)
            }

            if let accountBalance = genericDecoder(decodable: AccountBalance.self, from: data) {
                return self.handle(accountBalance: accountBalance)
            }

            if let accountInfo = genericDecoder(decodable: AccountInfo.self, from: data) {
                return self.handle(accountInfo: accountInfo) {
                    self.socket.send(endpoint: .accountBlockCount(address: self.address))
                }
            }

            if let pendingBlocks = genericDecoder(decodable: PendingBlocks.self, from: data) {
                return self.handle(pendingBlocks: pendingBlocks)
            }

            if let count = genericDecoder(decodable: AccountBlockCount.self, from: data) {
                return self.handle(accountBlockCount: count) {
                    self.socket.sendMultiple(endpoints: [
                        .accountPending(address: self.address),
                        .accountHistory(address: self.address, count: self.lastBlockCount.value),
                        .accountBalance(address: self.address)
                    ])
                }
            }

            if let newFrontierHash = genericDecoder(decodable: HashReceive.self, from: data) {
                self._previousFrontierHash.value = newFrontierHash.hash

                return
            }

            if let errorMessage = genericDecoder(decodable: ErrorMessage.self, from: data) {
                switch errorMessage.error {
                case .oldBlock: self.socket.send(endpoint: .accountBlockCount(address: self.address))
                case .fork, .accountNotFound: break
                }
            }

//            print("fail, did not have an object for \(message)")
        }

        // Mark: - Open the web socket

        socket.open()

        // Mark: - Producer for _previousFrontierHash

        _previousFrontierHash.producer.startWithValues { hash in
                guard let source = self.pendingBlocks.keys.first, let amount = self.pendingBlocks[source]?.transactionAmount else {
                    self.isCurrentlySyncing.value = false
                    self.currentlyReceivingHash.value = nil

                    return
                }

            self.processReceive(source: source, amount: amount, previous: hash)
        }
    }

    deinit {
        socket.close()
        disposable.dispose()

        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "ReestablishConnection"), object: nil)
    }

    /// Only use this function for Send transactions
    /// its really only important for displaying an accurate amount in the case of a mitm
    func verifySignature(stateBlock block: StateBlock) -> Bool {
        var blockTypes: [BlockType] = [.open(sendBlockHash: block.link), .receive(sendBlockHash: block.link)]

        if let toAddress = block.toAddress {
            blockTypes.append(.send(destinationAddress: toAddress))
        }

        for blockType in blockTypes {
            let ep = Endpoint.createStateBlock(
                type: blockType,
                previous: block.previous,
                remainingBalance: block.transactableBalance.stringValue,
                work: block.work,
                fromAccount: block.accountAddress,
                representative: block.representativeAddress,
                privateKey: privateKey
            )

            if ep.stringify()!.contains(block.signature) {
                return true
            }
        }

        return false
    }

    func getHeadBlock() {
        socket.send(endpoint: Endpoint.getBlock(frontierHash: previousFrontierHash!))
    }

    func fetchLatestPrices() {
        priceService.fetchLatestPrices()
    }

    func refresh(andFetchLatestFrontier fetchLatest: Bool = false) {
        priceService.fetchLatestPrices()

        if fetchLatest {
            socket.send(endpoint: .accountInfo(address: address))
        } else {
            socket.send(endpoint: .accountBlockCount(address: address))
        }

        checkAndOpenSockets()
    }

    func checkAndOpenSockets() {
        switch socket.readyState {
        case .closed: socket.open()
        case .open, .closing, .connecting: break
        }
    }

    func update(localCurrency currency: Currency) {
        priceService.update(localCurrency: currency)
    }

    // MARK: - Socket Handler Functions

    private func handle(accountCheck: AccountCheck, completion: (() -> Void)) {
        self.addressIsOnNetwork.value = accountCheck.ready

        completion()
    }

    private func handle(accountInfo: AccountInfo, completion: () -> Void) {
        self._previousFrontierHash.value = accountInfo.frontier

        completion()
    }

    private func handle(accountSubscribe: AccountSubscribe, completion: (() -> Void)) {
        // Subscribe and update the Nano account balance text
        self.accountSubscribe = accountSubscribe

        if userService.fetchCredentials()?.socketUUID == nil {
            userService.update(credentials: credentials, uuid: accountSubscribe.uuid)
        }

        self.lastBlockCount.value = accountSubscribe.blockCount

        if let balance = accountSubscribe.transactableBalance {
            self._transactableAccountBalance.value = balance
        }

        completion()
    }

    private func handle(accountBalance: AccountBalance) {
        if !addressIsOnNetwork.value { addressIsOnNetwork.value = true }

        if let balance = accountBalance.transactableBalance {
            self._transactableAccountBalance.value = balance
        }
    }

    private func handle(accountHistory: AccountHistory) {
        self.accountHistory = accountHistory

        // Find new transactions, if any, and insert into `transactions` appropriately
        let newTransactions: [NanoTransaction] = accountHistory.transactions.compactMap { txn in
            guard let hash = txn.hash else { return nil }
            let hashes = self.transactions.value.compactMap { $0.hash }

            return hashes.contains(hash) ? nil : .finished(txn)
        }

        if initialLoadComplete {
            transactions.value.insert(contentsOf: newTransactions, at: 0)
        } else {
            transactions.value.append(contentsOf: newTransactions)
            initialLoadComplete = true
        }
    }

    /// Result of .accountPending
    private func handle(pendingBlocks: PendingBlocks) {
        var pending = pendingBlocks
        self.pendingBlocks = pending.setPendingItemHashes() // TODO: can probably remove this function

        // Process first pending block, rest will follow in the producer above
        guard
            let source = self.pendingBlocks.first?.key,
            let amount = self.pendingBlocks[source]?.transactionAmount
        else { return }

        processReceive(source: source, amount: amount, previous: previousFrontierHash)
    }

    private func createStateBlockForOpen(forSource source: String, amount: NSDecimalNumber, completion: @escaping (() -> Void)) {
        RaiCore().createWorkForOpenBlock(withPublicKey: credentials.publicKey) { work in
            guard let work = work else { return completion() }

            let representative = Address(self.randomRepresentative())!
            let stateBlock = Endpoint.createStateBlock(
                type: .open(sendBlockHash: source),
                previous: "",
                remainingBalance: amount.stringValue,
                work: work,
                fromAccount: self.address,
                representative: representative,
                privateKey: self.credentials.privateKey
            )

            self.temporaryRepresentative = representative

            self.socket.send(endpoint: stateBlock)

            completion()
        }
    }

    private func createStateBlockForReceive(previousFrontierHash previous: String, source: String, amount: NSDecimalNumber, work: String) {
        let stateBlock = Endpoint.createStateBlock(
            type: .receive(sendBlockHash: source),
            previous: previous,
            remainingBalance: self.transactableAccountBalance.value.adding(amount).stringValue,
            work: work,
            fromAccount: self.address,
            representative: self.representative!,
            privateKey: credentials.privateKey
        )

        socket.send(endpoint: stateBlock)
    }

    private func handle(accountBlockCount: AccountBlockCount, completion: () -> Void) {
        self.lastBlockCount.value = accountBlockCount.count

        completion()
    }

    /// These are blocks sent over the wire when your app is open for you to receive
    private func handle(subscriptionBlock: SubscriptionTransaction, completion: @escaping () -> Void) {
        guard let myAddress = subscriptionBlock.toAddress, (subscriptionBlock.transactionType == .state || subscriptionBlock.transactionType == .send), myAddress == address else { return }

        processReceive(source: subscriptionBlock.source, amount: subscriptionBlock.transactionAmount, previous: previousFrontierHash) { completion() }
    }

    /// A general function that either processes the block as an open block or a receive block
    private func processReceive(source: String, amount: NSDecimalNumber, previous: String?, completion: (() -> Void)? = nil) {
        if let previous = previous {
            RaiCore().createWork(previousHash: previous) { work in
                guard let work = work else { return }

                self.pendingBlocks[source] = nil

                self.createStateBlockForReceive(previousFrontierHash: previous, source: source, amount: amount, work: work)

                if self.pendingBlocks.count == 0 { self.isCurrentlySyncing.value = false }
                self.lastBlockCount.value = self.lastBlockCount.value + 1

                completion?()
            }
        } else {
            guard lastBlockCount.value == 0 else { return }

            self.createStateBlockForOpen(forSource: source, amount: amount) {
                self.pendingBlocks[source] = nil

                if self.pendingBlocks.count == 0 { self.isCurrentlySyncing.value = false }
                self.lastBlockCount.value = 1

                completion?()
            }
        }
    }

    private func randomRepresentative() -> String {
        let count = UInt32(preconfiguredRepresentatives.count)
        let int = Int(arc4random_uniform(count - 1))

        return preconfiguredRepresentatives[int]
    }

    @objc func appWasReopened(_ notification: Notification) {
        checkAndOpenSockets()
    }

    func startAnalyticsService() {
        userService.updateUserAgreesToTracking(true)
        AnalyticsService.start()
    }

    func stopAnalyticsService() {
        userService.updateUserAgreesToTracking(false)
        AnalyticsService.stop()
    }

}
