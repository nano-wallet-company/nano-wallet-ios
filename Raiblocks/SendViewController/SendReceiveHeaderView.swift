//
//  SendReceiveHeaderView.swift
//  Nano
//
//  Created by Zack Shapiro on 12/29/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import UIKit

import Cartography


final class SendReceiveHeaderView: UIView {

    init(withType type: TransactionType) {
        super.init(frame: .zero)
        guard type != .open else { return }

        let image = UIImageView(image: UIImage(named: type.rawValue))
        addSubview(image)
        constrain(image) {
            $0.left == $0.superview!.left
            $0.centerY == $0.superview!.centerY + CGFloat(1)
        }

        let title = UILabel()
        title.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 18)
        title.textColor = type == .receive ? Styleguide.Colors.darkBlue.color : .white
        title.attributedText = NSAttributedString(string: type.rawValue.uppercased(), attributes: [.kern: 3.0])
        addSubview(title)
        constrain(title, image) {
            $0.centerY == $0.superview!.centerY + CGFloat(3)
            $0.left == $1.right + CGFloat(8)
            $0.right == $0.superview!.right
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
