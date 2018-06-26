//
//  SeedScanViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 12/15/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import UIKit

import Cartography
import ReactiveSwift


@objc protocol SeedScanViewControllerDelegate: class {
    func didReceiveSeedCode(walletSeed: String)
    func seedScanDidCancel()
}


class SeedScanViewController: UIViewController {

    private weak var scannerCameraView: ScannerViewContoller?

    weak var delegate: SeedScanViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let scannerCameraView = ScannerViewContoller()
        addChildViewController(scannerCameraView)
        view.addSubview(scannerCameraView.view)
        constrain(scannerCameraView.view) {
            $0.edges == $0.superview!.edges
        }
        self.scannerCameraView = scannerCameraView

        scannerCameraView.label?.text = "Scan a Nano Wallet Seed QR code to import an existing wallet.".localized()

        scanSeed()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var prefersStatusBarHidden: Bool { return true }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)

    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    func popCodeScanner() {
        navigationController?.popViewController(animated: true)
    }

    private func scanSeed() {
        scannerCameraView?.qrCodeProducer()
            .startWithValues {
                if let _ = Address($0) {
                    let alertController = UIAlertController(title: "Address Scanned".localized(), message: "You scanned a Nano address (xrb_...) instead of a Wallet Seed (64 character hexadecimal number).\n\nScan your Wallet Seed or press Cancel to type it in.".localized(), preferredStyle: .actionSheet)
                    alertController.addAction(UIAlertAction(title: "Scan Again".localized(), style: .default))
                    alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel) { _ in
                        self.delegate?.seedScanDidCancel()
                    })

                    self.present(alertController, animated: true, completion: nil)
                } else {
                    self.delegate?.didReceiveSeedCode(walletSeed: $0)
                }
        }
    }

}
