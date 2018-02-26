//
//  CodeScanViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 12/7/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import UIKit

import Cartography
import Crashlytics
import ReactiveSwift


@objc protocol CodeScanViewControllerDelegate: class {
    func didReceiveAddress(address: Address, amount: Double)
}


final class CodeScanViewController: ScannerViewContoller {

    private weak var scannerCameraView: ScannerViewContoller?

    weak var delegate: CodeScanViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let scannerCameraView = ScannerViewContoller()
        addChildViewController(scannerCameraView)
        view.addSubview(scannerCameraView.view)
        constrain(scannerCameraView.view) {
            $0.edges == $0.superview!.edges
        }
        self.scannerCameraView = scannerCameraView

        scannerCameraView.label?.text = "Scan a Nano or RaiBlocks address QR code"

        scanAddress()
    }

    override var prefersStatusBarHidden: Bool { return true }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    private func scanAddress() {
        scannerCameraView?.qrCodeProducer()
            .startWithValues { string in
                if let address = Address(string) {
                    self.delegate?.didReceiveAddress(address: address, amount: 0)
                } else if let parsedAddress = AddressParser.parse(string: string) {
                    self.delegate?.didReceiveAddress(address: parsedAddress.address, amount: parsedAddress.amount)
                } else {
                    Answers.logCustomEvent(withName: "Error Parsing QR Code", customAttributes: ["qr_code_string": string])
                }
            }
    }

}

final class AddressParser {

    static func parse(string: String) -> (address: Address, amount: Double)? {
        let _addressString = string.split(separator: ":")[1]
        let addressString = _addressString.split(separator: "?")[0]

        guard let address = Address(String(addressString)) else { return nil }

        var amount: Double = 0
        if String(_addressString).contains("amount=") {
            amount = Double(_addressString.split(separator: "=")[1]) ?? 0
        }

        return (address: address, amount: amount)
    }

}
