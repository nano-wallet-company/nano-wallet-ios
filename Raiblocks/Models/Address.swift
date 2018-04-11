//
//  Address.swift
//  Nano
//
//  Created by Zack Shapiro on 12/13/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import UIKit.UIColor


@objc final class Address: NSObject, Codable {

    private let value: String

    init?(_ address: String) {
        guard RaiCore().walletAddressIsValid(address) else { return nil }

        self.value = address
    }

    var hasXrbAddressFormat: Bool {
        return value.contains("xrb_")
    }

    var hasNanoAddressFormat: Bool {
        return value.contains("nano_")
    }

    var shortString: String {
        let frontStartIndex = String.Index(encodedOffset: 0)
        let frontEndIndex = String.Index(encodedOffset: hasXrbAddressFormat ? 9 : 10)

        let backStartIndex = String.Index(encodedOffset: value.count - 5)

        let front = value[frontStartIndex..<frontEndIndex]
        let back = value[backStartIndex...]

        return "\(front)...\(back)"
    }

    var shortAddressWithColor: NSAttributedString {
        let string = NSMutableAttributedString(string: shortString)

        let frontRange = NSMakeRange(0, hasXrbAddressFormat ? 9 : 10)
        let backRange = NSMakeRange(string.length - 5, 5)
        string.addAttribute(.foregroundColor, value: Styleguide.Colors.textLightBlue.color, range: frontRange)
        string.addAttribute(.foregroundColor, value: Styleguide.Colors.orange.color, range: backRange)

        return string
    }

    var longAddress: String {
        return value
    }

    var longAddressWithoutColor: NSAttributedString {
        return NSMutableAttributedString(string: value)
    }

    var longAddressWithColor: NSAttributedString {
        let string = NSMutableAttributedString(string: value)
        let frontRange = NSMakeRange(0, hasXrbAddressFormat ? 9 : 10)
        let backRange = NSMakeRange(string.length - 5, 5)
        string.addAttribute(.foregroundColor, value: Styleguide.Colors.textLightBlue.color, range: frontRange)
        string.addAttribute(.foregroundColor, value: Styleguide.Colors.orange.color, range: backRange)

        return string
    }

    var longAddressWithColorOnDarkBG: NSAttributedString {
        let string = NSMutableAttributedString(string: value)
        string.addAttribute(.foregroundColor, value: UIColor.white, range: NSMakeRange(0, string.length))

        let frontRange = NSMakeRange(0, hasXrbAddressFormat ? 9 : 10)
        let backRange = NSMakeRange(string.length - 5, 5)

        string.addAttribute(.foregroundColor, value: Styleguide.Colors.textLightBlue.color, range: frontRange)
        string.addAttribute(.foregroundColor, value: Styleguide.Colors.orange.color, range: backRange)

        return string
    }

    override func isEqual(_ object: Any?) -> Bool {
        return value == (object as? Address)?.value
    }

}
