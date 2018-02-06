//
//  CommonExtensions.swift
//  Nano
//
//  Created by Zack Shapiro on 12/8/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import UIKit

import EFQRCode
import ReactiveSwift
import Result
import SwiftWebSocket


func isiPhoneSE() -> Bool {
    return UIScreen.main.bounds.width == 320 && UIScreen.main.bounds.height == 568
}

func isiPhoneRegular() -> Bool {
    return UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 667
}

func isiPhonePlus() -> Bool {
    return UIScreen.main.bounds.width == 414 && UIScreen.main.bounds.height == 736
}

func isiPhoneX() -> Bool {
    return UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 812
}


extension WebSocket {

    func send(endpoint: Endpoint) {
//        print(endpoint)
        send(text: endpoint.stringify()!)
    }

    func sendMultiple(endpoints: [Endpoint]) {
        for endpoint in endpoints {
            send(endpoint: endpoint)
        }
    }

}


extension EFQRCode {

    public static func generate(
        content: String,
        size: EFIntSize = EFIntSize(width: 600, height: 600),
        backgroundColor: CIColor = CIColor.EFWhite(),
        foregroundColor: CIColor = CIColor.EFBlack(),
        watermark: CGImage? = nil,
        watermarkMode mode: EFWatermarkMode? = .scaleAspectFit
        ) -> CGImage? {

        let generator = EFQRCodeGenerator(
            content: content,
            size: size
        )
        generator.setWatermark(watermark: watermark, mode: mode)
        generator.setColors(backgroundColor: backgroundColor, foregroundColor: foregroundColor)
        return generator.generate()
    }

}
