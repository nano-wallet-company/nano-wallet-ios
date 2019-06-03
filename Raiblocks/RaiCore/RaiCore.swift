//
//  RaiCore.swfit.swift
//  Nano
//
//  Created by Zack Shapiro on 12/19/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import Foundation

import RealmSwift
import SwiftWebSocket


extension RaiCore {

    private var socketServerURL: URL? {
        let urlString = UserService.socketServerURL
        return URL(string: urlString)
    }

    func createWorkForOpenBlock(withPublicKey publicKey: String, completion: @escaping ((_ work: String?) -> Void)) {
        let socket = WebSocket(url: socketServerURL!)

        socket.event.message = { message in
            guard let str = message as? String, let data = str.asUTF8Data() else {
                AnalyticsEvent.createWorkFailedForOpenBlock.track()

                socket.close()

                return completion(nil)
            }

            if let work = try? JSONDecoder().decode(WorkGenerate.self, from: data) {
                socket.close()

                completion(work.work)
            }
        }

        socket.event.error = { _ in socket.close() }

        socket.open()
        socket.send(endpoint: .createWorkForOpenBlock(publicKey: publicKey))
    }

    func createWork(previousHash previous: String, completion: @escaping ((_ work: String?) -> Void)) {
        let socket = WebSocket(url: socketServerURL!)

        socket.event.message = { message in
            guard let str = message as? String, let data = str.asUTF8Data() else {
                AnalyticsEvent.createWorkFailed.track()

                socket.close()

                return completion(nil)
            }

            if let work = try? JSONDecoder().decode(WorkGenerate.self, from: data) {
                socket.close()

                completion(work.work)
            }
        }

        socket.event.error = { _ in socket.close() }

        socket.open()
        socket.send(endpoint: .createWork(previousHash: previous))
    }

}
