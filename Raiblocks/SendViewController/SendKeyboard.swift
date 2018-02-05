//
//  SendKeyboard.swift
//  Nano
//
//  Created by Zack Shapiro on 12/30/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import Foundation

import Cartography


protocol SendKeyboardDelegate: class {
    func valueWasSent(button: KeyboardButton)
}

final class SendKeyboard: UIView {

    var delegate: SendKeyboardDelegate?

    init() {
        super.init(frame: .zero)

        let vertStackView = UIStackView()
        vertStackView.axis = .vertical
        vertStackView.distribution = .fillEqually
        vertStackView.alignment = .fill
        addSubview(vertStackView)
        constrain(vertStackView) {
            $0.edges == $0.superview!.edges
        }

        func createHorizontalStackView(forButtons buttons: [SendKeyboardButton]) {
            let stackView = UIStackView()
            stackView.distribution = .fillEqually
            stackView.alignment = .fill
            stackView.axis = .horizontal
            stackView.spacing = 0
            vertStackView.addArrangedSubview(stackView)

            buttons.forEach {
                $0.delegate = self
                stackView.addArrangedSubview($0)
            }
        }

        createHorizontalStackView(forButtons: [
            SendKeyboardButton(withKey: "1"),
            SendKeyboardButton(withKey: "2"),
            SendKeyboardButton(withKey: "3")
        ])

        createHorizontalStackView(forButtons: [
            SendKeyboardButton(withKey: "4"),
            SendKeyboardButton(withKey: "5"),
            SendKeyboardButton(withKey: "6")
        ])

        createHorizontalStackView(forButtons: [
            SendKeyboardButton(withKey: "7"),
            SendKeyboardButton(withKey: "8"),
            SendKeyboardButton(withKey: "9")
        ])


        let divider = CurrencyService().localCurrency().locale.decimalSeparator
        createHorizontalStackView(forButtons: [
            SendKeyboardButton(withKey: divider ?? "."),
            SendKeyboardButton(withKey: "0"),
            SendKeyboardButton(withKey: "<")
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

enum KeyboardButton {
    case number(value: String)
    case backspace

    var stringValue: String {
        switch self {
        case .backspace: return "<"
        case let .number(value: val): return val
        }
    }

    var characterValue: Character {
        switch self {
        case .backspace: fatalError("This should never be used")
        case let .number(value: val): return Character(val)
        }
    }

    var valueIsDecimalIndicator: Bool {
        return self.stringValue == (CurrencyService().localCurrency().locale.decimalSeparator ?? ".")
    }
}


extension SendKeyboard: SendKeyboardButtonDelegate {

    func buttonWasPressed(string: String) {
        let keyboardButton: KeyboardButton = (string == "<") ? .backspace : .number(value: string)

        delegate?.valueWasSent(button: keyboardButton)
    }

}
