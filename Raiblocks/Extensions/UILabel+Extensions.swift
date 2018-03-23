//
//  UILabel+Extensions.swift
//  Nano
//
//  Created by Zack Shapiro on 3/22/18.
//  Copyright © 2018 Nano. All rights reserved.
//

import UIKit.UILabel

extension UILabel {

    func underline() {
        if let textString = self.text {
            let attributedString = NSMutableAttributedString(string: textString)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: NSRange(location: 0, length: attributedString.length))
            attributedText = attributedString
        }
    }

}
