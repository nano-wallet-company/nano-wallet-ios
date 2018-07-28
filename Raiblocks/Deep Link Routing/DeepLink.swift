//
//  DeepLink.swift
//  Raiblocks
//
//  Created by Fawaz Tahir on 7/28/18.
//  Copyright © 2018 Zack Shapiro. All rights reserved.
//

import Foundation

struct DeepLink {
    
    private enum `Type` {
        case application
        case universalLink
    }
    
    enum Destination {
        case home
        case view(TransactionMeta)
        case send(TransactionMeta?)
        case receive(TransactionMeta?)
        case settings
    }
    
    typealias Parameters = [String: String?]
    
    let url: URL
    let destination: Destination
    private let type: Type
}

extension DeepLink {
    
    private enum Scheme: String {
        case http
        case https
        case nano
        case xrb
    }
    
    private enum Host: String {
        case nano = "nano.org"
        case raiblocks = "raiblocks.com"
        case nanode = "nanode.co"
    }
    
    init?(url: URL) {
        self.url = url
        
        guard let scheme = Scheme(rawValue: url.scheme ?? "") else {
            // Scheme is unsupported.
            return nil
        }
        
        switch scheme {
        case .nano, .xrb:
            type = .application
            guard let destination = Destination(applicationQuery: url.query ?? "", parameters: url.queryDictionary) else {
                // Query is unsupported
                return nil
            }
            self.destination = destination
        case .http, .https:
            type = .universalLink
            guard let destination = Destination(universalLinkURL: url) else {
                // Host is unsupported
                return nil
            }
            self.destination = destination
        }
    }
}

fileprivate extension DeepLink.Destination {
    
    // Initializers
    
    init?(applicationQuery: String, parameters: DeepLink.Parameters?) {
        
        func meta(for parameters: DeepLink.Parameters?) -> TransactionMeta? {
            guard let parameters = parameters else { return nil }
            return AddressParser.parseDeepLink(parameters: parameters)
        }
        
        switch applicationQuery {
        case "home": self = .home
        case "view":
            guard let meta = meta(for: parameters) else { return nil }
            self = .view(meta)
        case "send":
            guard let meta = meta(for: parameters) else { return nil }
            self = .send(meta)
        case "receive":
            guard let meta = meta(for: parameters) else { return nil }
            self = .receive(meta)
        case "settings": self = .settings
        default:
            // Query is unsupported.
            return nil
        }
    }
    
    init?(universalLinkURL: URL) {
        guard let host = DeepLink.Host(rawValue: universalLinkURL.host ?? "") else {
            // Host is unsupported.
            return nil
        }
        
        // TODO: Parse the web urls of the respective host.
        switch host {
        case .nanode, .nano, .raiblocks:
            self = .home
        }
    }
}
