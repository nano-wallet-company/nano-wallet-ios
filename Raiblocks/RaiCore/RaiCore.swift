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


extension RaiCore {

    private var gpuServerURL: URL? {
        guard
            let path = Bundle.main.path(forResource: "Common", ofType: "plist"),
            let root = NSDictionary(contentsOfFile: path) as? [String: String],
            let urlString = root["gpuServerURL"]
        else { return nil }

        return URL(string: urlString)
    }

    func createWorkForOpenBlock(withPublicKey publicKey: String, completion: ((_ work: String) -> Void)?) {
        guard let data = Endpoint.createWorkForOpenBlock(publicKey: publicKey) else { return }

        doWork(forData: data) { completion?($0) }
    }

    func createWork(previousHash previous: String, completion: ((_ work: String) -> Void)?) {
        guard let data = Endpoint.createWork(previousHash: previous) else { return }

        doWork(forData: data) { completion?($0) }
    }

    private func doWork(forData data: Data, completion: ((_ work: String) -> Void)?) {
        guard let url = gpuServerURL else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                // check for fundamental networking error
                Crashlytics.sharedInstance().recordError(NanoWalletError.unableToGenerateWork)
                return
            }

            guard let work = try? JSONDecoder().decode(WorkGenerate.self, from: data) else { return }

            completion?(work.work)
        }.resume()
    }

}
