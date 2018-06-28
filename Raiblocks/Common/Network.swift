//
//  Network.swift
//  Raiblocks
//
//  Created by Ty Schenk on 6/26/18.
//  Copyright © 2018 Zack Shapiro. All rights reserved.
//

import Foundation

// MARK: Check Network
class Connectivity {
    //shared instance
    static let shared = Connectivity()

    enum ConnectivityStatus {
        case Reachable
        case NotReachable
    }

    func getStatus(completion: @escaping (ConnectivityStatus) -> Void ) {
        // create url request
        let urlString = "nanowalletcompany.com"
  
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.0
        
        // execute url request to determine if website is able to be viewed
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                  
            // return website is not reachable                                                  
            if let error = error {
                print("\(urlString) is not reachable, error: \(error.localizedDescription)")
                completion(.NotReachable)
            }
                                                              
            // return website is reachable                                                  
            if let httpResponse = response as? HTTPURLResponse {
                print("\(urlString) is reachable, status code: \(httpResponse.statusCode)")
                completion(.Reachable)
            }
        }
        task.resume()
    }
}
