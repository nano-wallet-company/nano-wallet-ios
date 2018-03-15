//
//  RaiCore.swfit.swift
//  Nano
//
//  Created by Zack Shapiro on 12/19/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import Foundation

import Crashlytics
import RealmSwift
import SwiftWebSocket


extension RaiCore {

    private var gpuServerURL: URL? {
        guard
            let path = Bundle.main.path(forResource: "Common", ofType: "plist"),
            let root = NSDictionary(contentsOfFile: path) as? [String: String],
            let urlString = root["gpuServerURL"]
        else { return nil }

        return URL(string: urlString)
    }

    func newCreateWorkForOpenBlock(withPublicKey publicKey: String, completion: @escaping ((_ work: String?) -> Void)) {
        let socket = WebSocket("wss://light.nano.org")

        socket.event.message = { message in
            guard let str = message as? String, let data = str.asUTF8Data() else {
                Answers.logCustomEvent(withName: "Create Work For Open Block Failed")

                return completion(nil)
            }

            if let work = try? JSONDecoder().decode(WorkGenerate.self, from: data) {
                completion(work.work)

                socket.close()
            }
        }

        socket.open()
        socket.send(endpoint: Endpoint.createWorkForOpenBlock(publicKey: publicKey))
    }

    func newCreateWork(previousHash previous: String, completion: @escaping ((_ work: String?) -> Void)) {
        let socket = WebSocket("wss://light.nano.org")

        socket.event.message = { message in
            guard let str = message as? String, let data = str.asUTF8Data() else {
                Answers.logCustomEvent(withName: "Create Work Failed")

                return completion(nil)
            }

            if let work = try? JSONDecoder().decode(WorkGenerate.self, from: data) {
                completion(work.work)

                socket.close()
            }
        }

        socket.open()
        socket.send(endpoint: Endpoint.createWork(previousHash: previous))
    }

    // TODO: refactor these after ublocks comes out
//    func createWorkForOpenBlock(withPublicKey publicKey: String, completion: ((_ work: String) -> Void)?) {
//        guard let data = Endpoint.createWorkForOpenBlock(publicKey: publicKey) else { return }
//        Endpoint.createWorkForOpenBlock(publicKey: publicKey).stringify()!

//        doWork(forData: data) { completion?($0) }
//    }

//    func createWork(previousHash previous: String, completion: ((_ work: String) -> Void)?) {
//        guard let data = Endpoint.createWork(previousHash: previous) else { return }
////        Endpoint.createWork(previous: previous).stringify()!
//
//        doWork(forData: data) { completion?($0) }
//    }

    func createWorkForSending(previousHash previous: String, completion: @escaping ((_ work: String?) -> Void)) {
        return completion(nil)


//        guard let data = Endpoint.createWork(previousHash: previous) else {
//            Answers.logCustomEvent(withName: "Unable to generate work for Send")
//
//            return completion(nil)
//        }
//
//        doWork(forData: data) { completion($0) }
    }

    private func doWork(forData data: Data, completion: ((_ work: String) -> Void)?) {
        guard let url = gpuServerURL else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                // TODO: check for fundamental networking error
                Answers.logCustomEvent(withName: "Unable to Generate Work", customAttributes: ["error": error?.localizedDescription ?? ""])
                return
            }

            guard let work = try? JSONDecoder().decode(WorkGenerate.self, from: data) else { return }

            completion?(work.work)
        }.resume()
    }

}
