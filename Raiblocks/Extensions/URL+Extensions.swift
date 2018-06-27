//
//  URL+Extensions.swift
//  Nano
//
//  Created by Zack Shapiro on 2/22/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

extension URL {

    var queryDictionary: [String: String]? {
        guard let query = URLComponents(string: self.absoluteString)?.query else { return nil}

        // TODO: add nano_ support later
        var queryStrings: [String: String] = [:]
        for item in query.components(separatedBy: ":") {
            if item.contains("xrb_") {
                let items = item.split(separator: "?")
                queryStrings["address"] = String(items[0])

                for i in items {
                    if i.contains("amount=") {
                        let val = i.split(separator: "=")[1]
                        queryStrings["amount"] = String(val)
                    }
                }
            }
        }

        for pair in query.components(separatedBy: "&") {
            let key = pair.components(separatedBy: "=")[0]

            let value = pair
                .components(separatedBy:"=")[1]
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? ""

            queryStrings[key] = value
        }

        return queryStrings
    }

}
