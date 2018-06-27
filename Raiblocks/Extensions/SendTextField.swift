//
//  SendTextField.swift
//  Nano
//
//  Created by Zack Shapiro on 12/21/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import UIKit

final class SendTextField: UITextField {

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        textColor = .white
        tintColor = .white
        textAlignment = .center
        placeholder = "0.00"
        inputView = UIView() // Don't show a keyboard
        font = Styleguide.Fonts.nunitoLight.font(ofSize: (isiPhoneSE() ? 17 : 20))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSmallerFontSize() {
        alpha = 0.5
        font = Styleguide.Fonts.nunitoLight.font(ofSize: (isiPhoneSE() ? 14 : 16))
    }

    func setLargerFontSize() {
        alpha = 1.0
        font = Styleguide.Fonts.nunitoLight.font(ofSize: (isiPhoneSE() ? 17 : 20))
    }

}
