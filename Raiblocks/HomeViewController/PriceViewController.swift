//
//  PriceViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import UIKit
import ReactiveSwift

import Cartography


class PriceViewController: UIViewController {

    enum PriceType {
        case nano
        case btc
        case localCurrency
    }

    private (set) var type: PriceType
    private let viewModel: HomeViewModel

    weak var priceLabel: UILabel?

    private let (lifetime, token) = Lifetime.make()

    init(type: PriceType, viewModel: HomeViewModel) {
        self.type = type
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        switch self.type {
        case .nano:
            viewModel.accountBalance
                .producer
                .take(during: lifetime)
                .observe(on: UIScheduler())
                .startWithValues { nanoBalance in
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.maximumFractionDigits = 10
                    formatter.locale = CurrencyService().localCurrency().locale

                    self.priceLabel?.text = formatter.string(from: nanoBalance.rawAsUsableAmount) ?? "0" + " NANO"
            }

        case .btc:
            let mark = Currency.btc.mark

            Property.combineLatest(viewModel.accountBalance, viewModel.lastBTCTradePrice)
                .producer
                .take(during: lifetime)
                .observe(on: UIScheduler())
                .startWithValues { nanoBalance, btcPrice in
                    guard let balance = nanoBalance.rawAsDouble else {
                        self.priceLabel?.text = "\(mark) 0"

                        return
                    }

                    let sats = btcPrice * 100_000_000
                    let myBtcBalance = (sats * balance) / 100_000_000

                    if let string = Currency.btc.numberFormatter.string(from: NSNumber(value: myBtcBalance)) {
                        // NumberFormatter doesn't include the mark for BTC which is why we include it here
                        self.priceLabel?.text = "\(mark) \(string)"
                    } else {
                        self.priceLabel?.text = "\(mark) 0"
                    }
            }

        case .localCurrency:
            viewModel.localCurrency
                .producer
                .flatMap(.latest) { _ in
                    return SignalProducer.combineLatest(viewModel.accountBalance.producer, viewModel.lastBTCTradePrice.producer, viewModel.lastBTCLocalCurrencyPrice.producer)
                }
                .take(during: lifetime)
                .observe(on: UIScheduler())
                .startWithValues { nanoBalance, btcPrice, localCurrencyPrice in
                    let currency = self.viewModel.localCurrency.value
                    let mark = currency.mark

                    guard let balance = nanoBalance.rawAsDouble else {
                        self.priceLabel?.text = "\(mark) 0"

                        return
                    }

                    let sats = btcPrice * 100_000_000
                    let myBtcBalance = (sats * balance) / 100_000_000
                    let localCurrencyValue = myBtcBalance * localCurrencyPrice

                    let string = currency.numberFormatter.string(from: NSNumber(floatLiteral: localCurrencyValue))
                    self.priceLabel?.text = string ?? "\(mark) 0"
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = Styleguide.Fonts.nunitoLight.font(ofSize: 20)
        view.addSubview(label)
        constrain(label) {
            $0.centerX == $0.superview!.centerX
            $0.centerY == $0.superview!.centerY
        }
        self.priceLabel = label

        if case .nano = self.type {
            let imageView = UIImageView(image: UIImage(named: "nanoCurrencyMarkWhite"))
            view.addSubview(imageView)
            constrain(imageView, label) {
                $0.right == $1.left - CGFloat(4)
                $0.top == $1.top + CGFloat(6)
            }
        }

        setDefaultValue()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func setDefaultValue() {
        switch type {
        case .nano:
            self.priceLabel?.text = "0"
        case .btc:
            self.priceLabel?.text = "\(Currency.btc.mark) 0"
        case .localCurrency:
            self.priceLabel?.text = "\(viewModel.localCurrency.value.mark) 0"
        }
    }

}
