//
//  DeepLinkURL.swift
//  Raiblocks
//
//  Created by Fawaz Tahir on 7/28/18.
//  Copyright © 2018 Zack Shapiro. All rights reserved.
//

import Foundation

private enum URLType {
    case application(Query)
    case webURL(Host)
}

private enum Scheme: String {
    case http
    case https
    case nano
    case xrb
}

private enum Query: String {
    case send
    case receive
    case settings
}

private enum Host: String {
    case nano = "nano.org"
    case raiblocks = "raiblocks.com"
    case nanode = "nanode.co"
}

struct DeepLinkURL {
    
    let url: URL
    private let type: URLType
    
    init?(url: URL) {
        guard let scheme = Scheme(rawValue: url.scheme ?? "") else {
            // Scheme is unsupported.
            return nil
        }
        self.url = url
        
        switch scheme {
        case .nano, .xrb:
            guard let query = Query(rawValue: url.query ?? "") else {
                // Query is unsupported
                return nil
            }
            type = .application(query)
        case .http, .https:
            guard let host = Host(rawValue: url.host ?? "") else {
                // Host is unsupported
                return nil
            }
            type = .webURL(host)
        }
    }
    
    var destination: DeepLink.Destination? {
        switch type {
        case .application(let query): return destination(for: query, queryParameters: url.queryDictionary)
        case .webURL(let host): return destination(for: host)
        }
    }
}

fileprivate extension DeepLinkURL {
    
    // MARK: Helpers
    
    private func destination(for host: Host) -> DeepLink.Destination {
        // TODO: Parse the web urls of the respective host.
        switch host {
        case .nanode, .nano, .raiblocks:
            return .home
        }
    }
    
    private func destination(for query: Query, queryParameters: DeepLink.Parameters?) -> DeepLink.Destination {
        switch query {
        case .send:
            return .send(AddressParser.parseDeepLink(queryParameters: queryParameters))
        case .receive:
            return .receive(AddressParser.parseDeepLink(queryParameters: queryParameters))
        case .settings:
            return .settings
        }
    }
}
