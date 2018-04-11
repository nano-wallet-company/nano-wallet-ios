//
//  CodeScanViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 12/7/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import UIKit

import Cartography
import ReactiveSwift


@objc protocol CodeScanViewControllerDelegate: class {
    func didReceiveAddress(address: Address, amount: NSDecimalNumber)
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
                    AnalyticsEvent.errorParsingQRCode.track(customAttributes: ["qr_code_string": string])
                }
            }
    }

}
