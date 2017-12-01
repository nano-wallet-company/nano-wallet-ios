//
//  NanoButton.swift
//  Raiblocks
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

import UIKit

import Cartography

final class NanoButton: UIButton {

    enum ButtonType {
        case lightBlue, lightBlueSend, darkBlue, orange

        var textColor: UIColor {
            switch self {
            case .darkBlue, .lightBlueSend: return .white
            case .lightBlue, .orange: return Styleguide.Colors.darkBlue.color
            }
        }

        var backgroundColor: UIColor {
            switch self {
            case .lightBlue, .darkBlue:
                return Styleguide.Colors.lightBlue.color.withAlphaComponent(0.2)
            case .orange:
                return Styleguide.Colors.orange.color.withAlphaComponent(0.2)
            case .lightBlueSend:
                return Styleguide.Colors.lightBlue.color
            }
        }
    }

    override var isEnabled: Bool {
        didSet {
            titleLabel?.alpha = isEnabled ? 1.0 : 0.5
 
            super.isEnabled = isEnabled
        }
    }

    init(withType type: ButtonType) {
        super.init(frame: .zero)

        layer.cornerRadius = 3
        clipsToBounds = true

        titleLabel?.textColor = type.textColor
        titleLabel?.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 17)
        setBackgroundColor(color: type.backgroundColor, forState: .normal)
        setBackgroundColor(color: type.backgroundColor.darkerColor(percent: 0.2), forState: .highlighted)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAttributedTitle(_ title: String?, withKerning kern: Double = 3) {
        guard let title = title else { return }
        let text = NSAttributedString(string: title, attributes: [.kern: kern])

        super.setAttributedTitle(text, for: .normal)
    }

}
