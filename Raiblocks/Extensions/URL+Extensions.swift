//
//  URL+Extensions.swift
//  Nano
//
//  Created by Zack Shapiro on 2/22/18.
//  Copyright © 2018 Nano. All rights reserved.
//

extension URL {

    var queryDictionary: [String: String]? {
        guard let query = URLComponents(string: self.absoluteString)?.query else { return nil}

        var queryStrings: [String: String] = [:]
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
