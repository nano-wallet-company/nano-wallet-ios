//
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

import UIKit

import Cartography
import QRCode

struct ReceiveViewModel {
    let address: Address
}

final class SharableWidget: UIView {

}

class ReceiveViewController: UIViewController {

    let viewModel: ReceiveViewModel

    init(viewModel: ReceiveViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // TODO: add pan gesture recgnizer
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        // MARK: - Navigation Controller Setup

        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.tintColor = Styleguide.Colors.lightBlue.color
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.shadowImage = UIImage() // hide the bottom border

        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: Styleguide.Colors.darkBlue.color,
            .font: Styleguide.Fonts.sofiaRegular.font(ofSize: 17),
            .kern: 5.0
        ]
        self.navigationItem.titleView = SendReceiveHeaderView(withType: .receive)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "dismissBlack"), style: .plain, target: self, action: #selector(dismissVC))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "share"), style: .plain, target: self, action: #selector(share(_:)))
        self.navigationItem.rightBarButtonItem?.tintColor = Styleguide.Colors.lightBlue.color

        // MARK: - UI Elements

        let scanLabel = UILabel()
        scanLabel.numberOfLines = 2
        scanLabel.textAlignment = .center
        scanLabel.text = """
        Scan the QR code
        to receive NANO
        """
        scanLabel.lineBreakMode = .byWordWrapping
        scanLabel.font = Styleguide.Fonts.nunitoLight.font(ofSize: 20)
        view.addSubview(scanLabel)
        constrain(scanLabel) {
            $0.top == $0.superview!.top + CGFloat(22)
            $0.width == $0.superview!.width * CGFloat(0.5)
            $0.centerX == $0.superview!.centerX
        }

        let qr = QRCode(viewModel.address.longAddress)!
        let imageView = UIImageView(image: qr.image!)
        view.addSubview(imageView)
        constrain(imageView, scanLabel) {
            $0.width == $0.superview!.width * CGFloat(0.45)
            $0.height == $0.superview!.width * CGFloat(0.45)
            $0.top == $1.bottom + CGFloat(34)
            $0.centerX == $0.superview!.centerX
        }

        let addressLabel = UILabel()
        addressLabel.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 16)
        addressLabel.attributedText = NSAttributedString(string: "NANO Address".uppercased(), attributes: [.kern: 5.0])
        view.addSubview(addressLabel)
        constrain(addressLabel, imageView) {
            $0.centerX == $1.centerX
            $0.top == $1.bottom + CGFloat(54)
        }

        let copyButton = NanoButton(withType: .lightBlue)
        copyButton.setAttributedTitle("COPY")
        copyButton.addTarget(self, action: #selector(copyAddress), for: .touchUpInside)
        view.addSubview(copyButton)
        constrain(copyButton) {
            $0.centerX == $0.superview!.centerX
            $0.bottom == $0.superview!.bottom - CGFloat((isiPhoneX() ? 34 : 20))
            $0.height == CGFloat(55)
            $0.width == $0.superview!.width * CGFloat(0.80)
        }


        // TODO: make this pan, give it some fidelity
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissVC))
        gestureRecognizer.direction = .down
        view.addGestureRecognizer(gestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func copyAddress() {
        UIPasteboard.general.string = self.viewModel.address.longAddress

        let ac = UIAlertController(title: "Your Nano Address Has Been Copied", message: "Give someone your address to receive Nano in your wallet", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Done", style: .default))
        present(ac, animated: true, completion: nil)
    }

    @objc func share(_ button: UIButton) {
        var activityItems: [Any] = []

        activityItems = [viewModel.address.longAddress]
        // create image and share via share sheet
        // if let image = eventCardImage { activityItems.append(image) }

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = button
        activityViewController.excludedActivityTypes = [.assignToContact, .addToReadingList]

        present(activityViewController, animated: true, completion: nil)
    }

    @objc func dismissVC() {
        dismiss(animated: true, completion: nil)
    }
}

