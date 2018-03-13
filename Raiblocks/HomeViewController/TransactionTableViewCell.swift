//
//  Copyright © 2017 Nano. All rights reserved.
//

import UIKit

import Cartography

protocol TransactionTableViewCellDelegate: class {
    func cellWasLongPressed(address: Address)
}


final class TransactionTableViewCell: UITableViewCell {

    private var icon: UIImageView?
    private var nanoCurrencySymbol: UIImageView?
    private var amountLabel: UILabel?
    private var addressLabel: UILabel?

    var delegate: TransactionTableViewCellDelegate?

    var viewModel: TransactionViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }

            if let type = viewModel.type {
                self.icon?.image = UIImage(named: type.rawValue)
            } else {
                self.icon?.image = UIImage(named: TransactionType.receive.rawValue)
            }

            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = isiPhoneSE() ? 7 : 10
            formatter.locale = CurrencyService().localCurrency().locale

            self.amountLabel?.text = formatter.string(from: viewModel.amount) ?? "0"
            self.addressLabel?.attributedText = viewModel.address?.shortAddressWithColor
            self.nanoCurrencySymbol?.image = viewModel.type == .send ? UIImage(named: "nanoCurrencyMarkBlue") : UIImage(named: "nanoCurrencyMarkGrey")
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let icon = UIImageView()
        addSubview(icon)
        constrain(icon) {
            $0.left == $0.superview!.left + CGFloat(24)
            $0.centerY == $0.superview!.centerY
        }
        self.icon = icon

        let nanoCurrencySymbol = UIImageView()
        addSubview(nanoCurrencySymbol)
        constrain(nanoCurrencySymbol, icon) {
            $0.left == $1.right + (isiPhoneSE() ? CGFloat(8) : CGFloat(16))
            $0.top == $1.top
        }
        self.nanoCurrencySymbol = nanoCurrencySymbol

        let amountLabel = UILabel()
        amountLabel.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 20)
        amountLabel.textColor = Styleguide.Colors.darkBlue.color
        addSubview(amountLabel)
        constrain(amountLabel, nanoCurrencySymbol) {
            $0.centerY == $0.superview!.centerY
            $0.left == $1.right + CGFloat(2)
        }
        self.amountLabel = amountLabel

        let addressLabel = UILabel()
        addressLabel.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 14)
        addSubview(addressLabel)
        constrain(addressLabel) {
            $0.top == $0.superview!.top + CGFloat(24)
            $0.right == $0.superview!.right - CGFloat(24)
        }
        self.addressLabel = addressLabel

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(copyAddress(_:)))
        gestureRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(gestureRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        icon?.image = nil
        icon?.alpha = 1.0
        nanoCurrencySymbol?.image = nil
        nanoCurrencySymbol?.alpha = 1.0

        amountLabel?.textColor = .black
        amountLabel?.text = nil
        amountLabel?.alpha = 1.0
        addressLabel?.text = nil
        addressLabel?.alpha = 1.0
    }

    @objc func copyAddress(_ recognizer: UILongPressGestureRecognizer) {
        guard let address = viewModel?.address else { return }

        if recognizer.state == .ended {
            delegate?.cellWasLongPressed(address: address)
        }
    }
}

