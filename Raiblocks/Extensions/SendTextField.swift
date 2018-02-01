//
//  SendTextField.swift
//  Nano
//
//  Created by Zack Shapiro on 12/21/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import UIKit

import ReactiveSwift
import ReactiveCocoa


final class SendTextField: UITextField {

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        textColor = .white
        tintColor = .white
        textAlignment = .center
        placeholder = "0.00"
        inputView = UIView() // Don't show a keyboard
        font = Styleguide.Fonts.nunitoLight.font(ofSize: 20)

//        textContainerInset = UIEdgeInsets(top: 20, left: 60, bottom: 20, right: 60)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSmallerFontSize() {
        alpha = 0.5
        font = Styleguide.Fonts.nunitoLight.font(ofSize: 16)
    }

    func setLargerFontSize() {
        alpha = 1.0
        font = Styleguide.Fonts.nunitoLight.font(ofSize: 20)
    }

}
