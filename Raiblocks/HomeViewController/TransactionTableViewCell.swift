//
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

import UIKit

import Cartography


enum CellState {
    case isPending, isReceiving, _default
}

final class TransactionTableViewCell: UITableViewCell {

    private var icon: UIImageView?
    private var nanoCurrencySymbol: UIImageView?
    private var amountLabel: UILabel?
    private var addressLabel: UILabel?

    // Not currently in use, may be able to remove
    var state: CellState = ._default {
        didSet {
            switch state {
            case ._default:
                self.icon?.alpha = 1.0
                self.nanoCurrencySymbol?.alpha = 1.0
                self.amountLabel?.alpha = 1.0
                self.addressLabel?.alpha = 1.0

                self.addressLabel?.attributedText = viewModel?.address?.shortAddressWithColor

            case .isPending:
                self.icon?.alpha = 0.2
                self.nanoCurrencySymbol?.alpha = 0.2
                self.amountLabel?.alpha = 0.2
                self.addressLabel?.alpha = 0.2

                self.addressLabel?.text = "Receiving (Pending)"

            case .isReceiving:
                self.icon?.alpha = 0.4
                self.nanoCurrencySymbol?.alpha = 0.4
                self.amountLabel?.alpha = 0.4
                self.addressLabel?.alpha = 0.4

                self.addressLabel?.text = "Receiving..."
            }
        }
    }

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
            formatter.maximumFractionDigits = 10

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
            $0.left == $0.superview!.left + CGFloat(40)
            $0.centerY == $0.superview!.centerY
        }
        self.icon = icon

        let nanoCurrencySymbol = UIImageView()
        addSubview(nanoCurrencySymbol)
        constrain(nanoCurrencySymbol, icon) {
            $0.left == $1.right + CGFloat(16)
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        state = ._default

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
}

