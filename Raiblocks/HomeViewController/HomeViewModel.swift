//
//  HomeViewModel.swift
//  Nano
//
//  Created by Zack Shapiro on 12/20/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import Crashlytics
import ReactiveSwift
import RealmSwift
import Result
import SwiftWebSocket


final class HomeViewModel {

    let socket: WebSocket
    private let hashStreamingSocket: WebSocket

    private let priceService = PriceService()

    var credentials: Credentials {
        guard
            let seed = UserService().currentUserSeed(),
            let credentials = Credentials(seedString: seed)
        else {
            Answers.logCustomEvent(withName: "App crashed due to missing Credentials")

            fatalError("There should always be a seed")
        }

        return credentials
    }
    var privateKey: Data {
        return credentials.privateKey
    }

    private let _frontierBlockHash = MutableProperty<String?>(nil)
    var frontierBlockHash: ReactiveSwift.Property<String?>

    var initialLoadComplete: Bool = false
    let transactions = MutableProperty<[NanoTransaction]>([])

    var pendingTransactions: [NanoTransaction] {
        return transactions.value.filter { $0.isPending }
    }

    let isCurrentlySyncing = MutableProperty<Bool>(false)

    let _hasNetworkConnection = MutableProperty<Bool>(false)
    var hasNetworkConnection: ReactiveSwift.Property<Bool>

    let currentlyReceivingHash = MutableProperty<String?>(nil)

    let addressIsOnNetwork = MutableProperty<Bool>(false)
    var address: Address {
        return credentials.address
    }

    private var accountHistory: AccountHistory?

    private var accountSubscribe: AccountSubscribe?

    private let _accountBalance = MutableProperty<NSDecimalNumber>(0)
    var accountBalance: ReactiveSwift.Property<NSDecimalNumber>

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
    private var _previousFrontierHash: String?
    var previousFrontierHash: String? {
        get {
            if let _ = self._previousFrontierHash {
                return self._previousFrontierHash
            } else if let _ = accountSubscribe?.frontierBlockHash {
                return accountSubscribe?.frontierBlockHash
            } else {
                return nil // if this is nil for some reason, we should go out and get the frontierBlockHash
            }
        }
    }

    init() {
        guard
            let path = Bundle.main.path(forResource: "Common", ofType: "plist"),
            let root = NSDictionary(contentsOfFile: path) as? [String: String],
            let urlString = root["socketServerURL"]
        else { fatalError("Could not load socket server URL") }

        self.frontierBlockHash = ReactiveSwift.Property<String?>(_frontierBlockHash)
        self.accountBalance = ReactiveSwift.Property<NSDecimalNumber>(_accountBalance)
        self.transactableAccountBalance = ReactiveSwift.Property<NSDecimalNumber>(_transactableAccountBalance)
        self.hasNetworkConnection = ReactiveSwift.Property<Bool>(_hasNetworkConnection)

        // MARK: - Socket Setup

        self.socket = WebSocket(urlString)
        self.hashStreamingSocket = WebSocket(urlString)

        NotificationCenter.default.addObserver(self, selector: #selector(appWasReopened(_:)), name: Notification.Name(rawValue: "ReestablishConnection"), object: nil)

        socket.event.open = {
//            print("socket opened")
            self._hasNetworkConnection.value = true
            self.socket.sendMultiple(endpoints: [
                .accountSubscribe(address: self.address),
                .accountCheck(address: self.address),
            ])
        }

        socket.event.close = { code, reason, clean in
            Answers.logCustomEvent(withName: "Socked Closed in HomeVM", customAttributes: ["code": code, "reason": reason])

            self._hasNetworkConnection.value = false
            // print("CONNECTION WAS CLOSED")
        }

        socket.event.error = { error in
            Answers.logCustomEvent(withName: "Socket Error in HomeVM", customAttributes: ["error": error.localizedDescription])
            // print("error \(error)")
        }

        self.socket.event.message = { message in
//            print(message) // Uncomment for development
            guard let str = message as? String, let data = str.asUTF8Data() else { return }

            if let accountCheck = self.genericDecoder(decodable: AccountCheck.self, from: data) {
                return self.handle(accountCheck: accountCheck) {
                    self.socket.send(endpoint: .accountPending(address: self.address))
                }
            }

            if let subscriptionBlock = self.genericDecoder(decodable: SubscriptionTransaction.self, from: data) {
                return self.handle(subscriptionBlock: subscriptionBlock) {
                    self.socket.sendMultiple(endpoints: [
                        .accountHistory(address: self.address, count: self.lastBlockCount.value),
                        .accountBalance(address: self.address)
                    ])

                    self.priceService.fetchLatestPrices()
                }
            }

            if let accountSubscribe = self.genericDecoder(decodable: AccountSubscribe.self, from: data) {
                return self.handle(accountSubscribe: accountSubscribe) {
                    self.socket.send(endpoint: Endpoint.accountHistory(address: self.address, count: self.lastBlockCount.value))
                }
            }

            if let accountHistory = self.genericDecoder(decodable: AccountHistory.self, from: data) {
                return self.handle(accountHistory: accountHistory)
            }

            if let accountBalance = self.genericDecoder(decodable: AccountBalance.self, from: data) {
                return self.handle(accountBalance: accountBalance)
            }

            if let pendingBlocks = self.genericDecoder(decodable: PendingBlocks.self, from: data) {
                return self.handle(pendingBlocks: pendingBlocks)
            }

            if let count = self.genericDecoder(decodable: AccountBlockCount.self, from: data) {
                return self.handle(accountBlockCount: count ) {
                    self.socket.sendMultiple(endpoints: [
                        .accountPending(address: self.address),
                        .accountHistory(address: self.address, count: self.lastBlockCount.value),
                        .accountBalance(address: self.address)
                    ])
                }
            }

            if let newFrontierHash = self.genericDecoder(decodable: HashReceive.self, from: data) {
                return self._previousFrontierHash = newFrontierHash.hash
            }

//            print("fail, did not have an object for \(message)")
        }

        socket.open()
        hashStreamingSocket.open()
    }

    deinit {
        socket.close()
        hashStreamingSocket.close()

        disposable.dispose()

        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "ReestablishConnection"), object: nil)
    }

    func fetchLatestPrices() {
        priceService.fetchLatestPrices()
    }

    func refresh() {
        priceService.fetchLatestPrices()

        checkAndOpenSockets()
    }

    func checkAndOpenSockets() {
        switch socket.readyState {
        case .open: socket.send(endpoint: .accountBlockCount(address: address))
        case .closed: socket.open()
        case .closing, .connecting: break
        }

        switch hashStreamingSocket.readyState {
        case .closed: hashStreamingSocket.open()
        case .open, .closing, .connecting: break
        }
    }

    func update(localCurrency currency: Currency) {
        priceService.update(localCurrency: currency)
    }

    private func genericDecoder<T: Decodable>(decodable: T.Type, from data: Data) -> T? {
        return try? JSONDecoder().decode(decodable, from: data)
    }

    // MARK: - Socket Handler Functions

    private func handle(accountCheck: AccountCheck, completion: (() -> Void)) {
        self.addressIsOnNetwork.value = accountCheck.ready

        completion()
    }

    private func handle(accountSubscribe: AccountSubscribe, completion: (() -> Void)) {
        // Subscribe and update the Nano account balance text
        self.accountSubscribe = accountSubscribe
        self.lastBlockCount.value = accountSubscribe.blockCount

        self._accountBalance.value = accountSubscribe.totalBalance ?? 0
        self._transactableAccountBalance.value = accountSubscribe.transactableBalance ?? 0

        completion()
    }

    private func handle(accountBalance: AccountBalance) {
        if !addressIsOnNetwork.value { addressIsOnNetwork.value = true }

        self._accountBalance.value = accountBalance.totalBalance ?? 0
        self._transactableAccountBalance.value = accountBalance.transactableBalance ?? 0
    }

    private func handle(accountHistory: AccountHistory) {
        self.accountHistory = accountHistory

        // Find new transactions, if any, and insert into `transactions` appropriately
        let newTransactions: [NanoTransaction] = accountHistory.transactions.flatMap { txn in
            guard let hash = txn.hash else { return nil }
            let hashes = self.transactions.value.flatMap { $0.hash }

            return hashes.contains(hash) ? nil : .finished(txn)
        }

        if initialLoadComplete {
            transactions.value.insert(contentsOf: newTransactions, at: 0)
        } else {
            transactions.value.append(contentsOf: newTransactions)
            initialLoadComplete = true
        }
    }

    private func handle(pendingBlocks: PendingBlocks) {
        // result of .accountPending
        var pending = pendingBlocks
        self.pendingBlocks = pending.setPendingItemHashes()

        let transactions = pending.blocks.map({ $0.value })

        let newTransactions: [NanoTransaction] = transactions.flatMap { txn in
            guard let hash = txn.hash else { return nil }
            let hashes = self.transactions.value.flatMap { $0.hash }

            return hashes.contains(hash) ? nil : .pending(txn)
        }
        self.transactions.value.insert(contentsOf: newTransactions, at: 0)

        processPendingBlocks()
    }

    private func createOpenBlock(forSource source: String, completion: (() -> Void)? = nil) {
        RaiCore().createWorkForOpenBlock(withPublicKey: credentials.publicKey) { work in
            let pendingBlock = Endpoint.createOpenBlock(
                source: source,
                work: work,
                representative: self.randomRepresentative(),
                address: self.address,
                privateKey: self.privateKey
            )

            self.socket.send(endpoint: pendingBlock)

            completion?()
        }
    }

    private func processPendingBlocks() {
        self.isCurrentlySyncing.value = true

        let (signal, observer) = Signal<String, NoError>.pipe()
        let hashProducer: SignalProducer<String, NoError> = SignalProducer(signal)

        guard let firstPendingBlock = pendingBlocks.first else {
            self.isCurrentlySyncing.value = false
            self.currentlyReceivingHash.value = nil

            return
        }

        // Process first block
        processReceiveAndRemoveTransaction(source: firstPendingBlock.key, previous: previousFrontierHash)

        // Send values through the observer that the hashProducer below is listening to
        hashStreamingSocket.event.message = { message in
            guard let str = message as? String, let data = str.asUTF8Data() else { return }

            if let newFrontierHash = self.genericDecoder(decodable: HashReceive.self, from: data) {
                self._previousFrontierHash = newFrontierHash.hash

                observer.send(value: newFrontierHash.hash)
            }
        }

        disposable.inner = hashProducer.on(
                completed: {
                    self.isCurrentlySyncing.value = false
                    self.currentlyReceivingHash.value = nil
                    self.disposable.dispose()
                },

                value: { _ in
                    guard let firstPendingBlock = self.pendingBlocks.first, let previous = self.previousFrontierHash else {
                        self.isCurrentlySyncing.value = false
                        self.currentlyReceivingHash.value = nil

                        return
                    }

                    self.processReceiveAndRemoveTransaction(source: firstPendingBlock.key, previous: previous)
            }
        ).start()
    }

    private func createReceiveBlock(previousFrontierHash previous: String, source: String, work: String) {
        socket.send(endpoint: .createReceiveBlock(previous: previous, source: source, work: work, privateKey: credentials.privateKey))
    }

    private func handle(accountBlockCount: AccountBlockCount, completion: (() -> Void)) {
        self.lastBlockCount.value = accountBlockCount.count

        completion()
    }

    /// These are blocks sent over the wire when your app is open for you to receive
    private func handle(subscriptionBlock: SubscriptionTransaction, completion: @escaping (() -> Void)) {
        guard let myAddress = subscriptionBlock.toAddress, subscriptionBlock.transactionType == .send, myAddress == address else { return }

        processReceive(source: subscriptionBlock.source, previous: previousFrontierHash) { completion() }
    }

    /// A general function that either processes the block as an open block or a receive block
    private func processReceive(source: String, previous: String?, completion: @escaping (() -> Void)) {
        self.currentlyReceivingHash.value = source

        if let previous = previous {
            RaiCore().createWork(previousHash: previous) { work in
                self.createReceiveBlock(previousFrontierHash: previous, source: source, work: work)

                self.pendingBlocks[source] = nil
                if self.pendingBlocks.count == 0 { self.isCurrentlySyncing.value = false }
                self.lastBlockCount.value += self.lastBlockCount.value + 1

                completion()
            }
        } else {
            guard lastBlockCount.value == 0 else { return completion() }

            self.createOpenBlock(forSource: source) {
                self.pendingBlocks[source] = nil
                if self.pendingBlocks.count == 0 { self.isCurrentlySyncing.value = false }
                self.lastBlockCount.value = 1

                completion()
            }
        }
    }

    private func processReceiveAndRemoveTransaction(source: String, previous: String?) {
        processReceive(source: source, previous: previous) {
            if let justWorkedTransaction = self.transactions.value.filter({ $0.hash == self.currentlyReceivingHash.value && $0.isPending }).first,
                let index = self.transactions.value.index(of: justWorkedTransaction) {
                self.transactions.value.remove(at: index)
            }
            self.currentlyReceivingHash.value = nil

            self.socket.send(endpoint: .accountBlockCount(address: self.address))
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

}
