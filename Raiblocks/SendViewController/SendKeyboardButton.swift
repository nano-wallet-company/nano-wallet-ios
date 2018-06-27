//
//  SendKeyboardButton.swift
//  Nano
//
//  Created by Zack Shapiro on 12/30/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import UIKit

import Cartography


protocol SendKeyboardButtonDelegate: class {
    func buttonWasPressed(string: String)
}

final class SendKeyboardButton: UIButton {

    var label: UILabel?

    var delegate: SendKeyboardButtonDelegate?

    init(withKey key: String) {
        super.init(frame: .zero)

        setBackgroundColor(color: Styleguide.Colors.darkBlue.color, forState: .normal)
        setBackgroundColor(color: Styleguide.Colors.lightBlue.color, forState: .highlighted)

        addTarget(self, action: #selector(touchDidEnd(_:)), for: .touchUpInside)

        let label = UILabel()
        label.text = key
        label.textColor = Styleguide.Colors.lightBlue.color
        label.font = Styleguide.Fonts.nunitoRegular.font(ofSize: 20)
        addSubview(label)
        constrain(label) {
            $0.center == $0.superview!.center
        }
        self.label = label
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func touchDidEnd(_ sender: SendKeyboardButton) {
        guard let text = sender.label?.text else { return }

        delegate?.buttonWasPressed(string: text)
    }
}

