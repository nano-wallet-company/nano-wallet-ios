//
//  GenericFunctions.swift
//  Nano
//
//  Created by Zack Shapiro on 4/16/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

func genericDecoder<T: Decodable>(decodable: T.Type, from data: Data) -> T? {
    return try? JSONDecoder().decode(decodable, from: data)
}
