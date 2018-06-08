//
//  SeedConfirmationViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 1/19/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

import UIKit
import LocalAuthentication
import MobileCoreServices

import Cartography
import Fabric


class SeedConfirmationViewController: UIViewController {

    private var credentials: Credentials
    private var seedWasCopied = false

    private weak var textView: UITextView?

    init() {
        guard let credentials = Credentials(seed: RaiCore().createSeed()) else {
            AnalyticsEvent.trackCustomException("Credential Creation Failed")

            fatalError()
        }
        self.credentials = credentials
        UserService().store(credentials: credentials)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool { return true }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if !appDelegate.devConfig.skipLegal {
            if !credentials.hasCompletedLegalAgreements {
                let vc = LegalViewController(useForLoggedInState: false)
                vc.delegate = self
                present(vc, animated: false)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let credentials = UserService().fetchCredentials(), credentials.hasCompletedLegalAgreements {
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let logo = UIImageView(image: UIImage(named: "largeNanoMarkBlue"))
        view.addSubview(logo)
        constrain(logo) {
            $0.top == $0.superview!.top + CGFloat(44)
            $0.centerX == $0.superview!.centerX
        }

        let titleLabel = UILabel()
        titleLabel.text = "Your Nano Wallet Seed"
        titleLabel.textColor = Styleguide.Colors.darkBlue.color
        titleLabel.font = Styleguide.Fonts.nunitoRegular.font(ofSize: 20)
        view.addSubview(titleLabel)
        constrain(titleLabel, logo) {
            $0.centerX == $1.centerX
            $0.top == $1.bottom + CGFloat(20)
        }

        let button = NanoButton(withType: .lightBlue)
        button.addTarget(self, action: #selector(continueButtonWasPressed), for: .touchUpInside)
        button.setAttributedTitle("I Understand, Continue", withKerning: 0.8)
        view.addSubview(button)
        constrain(button) {
            $0.centerX == $0.superview!.centerX
            $0.bottom == $0.superview!.bottom - CGFloat((isiPhoneX() ? 34 : 20))
            $0.width == $0.superview!.width * CGFloat(0.8)
            $0.height == CGFloat(55)
        }

        let textView = UITextView()
        textView.text = credentials.seed
        textView.isEditable = false
        textView.layer.cornerRadius = 3
        textView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textView.clipsToBounds = true
        textView.textColor = .white
        textView.backgroundColor = Styleguide.Colors.darkBlue.color
        textView.tintColor = Styleguide.Colors.lightBlue.color
        textView.textAlignment = .center
        textView.returnKeyType = .done
        textView.isScrollEnabled = false
        if isiPhoneSE() {
            textView.textContainerInset = UIEdgeInsets(top: 15, left: 20, bottom: 12, right: 20)
        } else {
            textView.textContainerInset = UIEdgeInsets(top: 15, left: 30, bottom: 12, right: 30)
        }
        textView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(copySeed)))
        view.addSubview(textView)
        constrain(textView, button) {
            $0.height == CGFloat(80)
            $0.bottom == $1.top - CGFloat(33)
            $0.width == $1.width
            $0.centerX == $1.centerX
        }
        self.textView = textView

        let smallCopy = UILabel()
        smallCopy.font = Styleguide.Fonts.notoSansRegular.font(ofSize: 14)
        smallCopy.textColor = Styleguide.Colors.darkBlue.color
        smallCopy.attributedText = NSAttributedString(string: "Tap to copy", attributes: [.kern: 1.0])
        view.addSubview(smallCopy)
        constrain(smallCopy, textView) {
            $0.centerX == $1.centerX
            $0.top == $1.bottom + CGFloat(6)
        }

        let textBody = UITextView()
        textBody.textAlignment = .left
        textBody.isUserInteractionEnabled = true
        textBody.isEditable = false
        textBody.isSelectable = false
        let attributedText = NSMutableAttributedString(string: "Your Nano Wallet Seed is how we generate your wallet. It’s also how you log into the iOS Wallet or any of our other wallets, including NanoWallet.io.\n\nIf you lose your Wallet Seed, your funds cannot be recovered.\n\nKeep your Wallet Seed somewhere safe (like password management software or print it out and put it in a safe).\n\nNever give it to anyone, ever.")
        attributedText.addAttribute(.foregroundColor, value: Styleguide.Colors.darkBlue.color, range: NSMakeRange(0, attributedText.length))
        attributedText.addAttribute(.font, value: Styleguide.Fonts.nunitoRegular.font(ofSize: 18), range: NSMakeRange(0, attributedText.length))
        attributedText.addAttribute(.foregroundColor, value: Styleguide.Colors.red.color, range: NSMakeRange(150, 64)) // Middle sentence "If you lose your wallet..."
        attributedText.addAttribute(.foregroundColor, value: Styleguide.Colors.red.color, range: NSMakeRange(attributedText.length - 30, 30)) // last sentence "Never give it..."
        textBody.attributedText = attributedText
        textBody.isScrollEnabled = true
        view.addSubview(textBody)
        constrain(textBody, titleLabel, textView) {
            $0.width == $2.width
            $0.centerX == $0.superview!.centerX

            if isiPhoneSE() {
                $0.top == $1.bottom + CGFloat(22)
                $0.bottom == $2.top - CGFloat(22)
            } else {
                $0.top == $1.bottom + CGFloat(33)
                $0.bottom == $2.top - CGFloat(33)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func copySeed() {
        AnalyticsEvent.seedCopied.track(customAttributes: ["location": "seed confirmation"])

        textView?.selectedTextRange = nil

        DispatchQueue.global().async {
            UIPasteboard.general.setObjects([self], localOnly: false, expirationDate: Date().addingTimeInterval(120))

            DispatchQueue.main.sync {
                let ac = UIAlertController(title: "Wallet Seed Copied", message: "Your Wallet Seed is pastable for 2 minutes.\nAfter, you can access it in Settings.\n\nPlease backup your Wallet Seed somewhere safe like  password management software or print it out and put it in a safe.", preferredStyle: .actionSheet)
                ac.addAction(UIAlertAction(title: "Okay", style: .default))

                self.present(ac, animated: true, completion: nil)
            }
        }
    }

    @objc func continueButtonWasPressed() {
        AnalyticsEvent.seedConfirmatonContinueButtonPressed.track()

        let ac = UIAlertController(title: "Welcome to Nano Wallet!", message: "Please confirm you have properly stored your Wallet Seed somewhere safe.", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "I have backed up my Wallet Seed", style: .default) { _ in
            self.navigationController?.pushViewController(HomeViewController(viewModel: HomeViewModel()), animated: true)
        })
        ac.addAction(UIAlertAction(title: "Back", style: .cancel))

        present(ac, animated: true, completion: nil)
    }

}


extension SeedConfirmationViewController: NSItemProviderWriting {

    static var writableTypeIdentifiersForItemProvider: [String] {
        return [kUTTypeUTF8PlainText as String]
    }

    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        DispatchQueue.main.sync {
            completionHandler(credentials.seed.data(using: .utf8), nil)
        }

        return nil
    }

}


extension SeedConfirmationViewController: LegalViewControllerDelegate {

    func didFinishWithLegalVC() {
        let ac = UIAlertController(title: "Analytics Opt-In", message: """
        Nano Wallet Company LLC ('we' or 'us') would like to collect your device ID, as well as usage metrics and error and crash reports relating to your use of this Nano Wallet mobile application (the 'Wallet'), in order to help us understand how users are using the Wallet and where errors might occur in the Wallet, and to use this data to help us maintain, develop and improve the Wallet and our products and services.

            No data about your name, contact information, funds, Nano tokens, Wallet Seed or private keys are ever collected through the Wallet. You can see exactly what types of data we collect through the Wallet by viewing our Privacy Policy.

            Do you consent to our collection and use of this data for these purposes? (Your consent is not a prerequisite for using the Wallet and, if you consent, you will have the right to withdraw your consent at any time as described in the Privacy Policy.)
        """, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "I Consent", style: .default) { _ in
            UserService().updateUserAgreesToTracking(true)
        })
        ac.addAction(UIAlertAction(title: "I Do Not Consent", style: .default) { _ in
            UserService().updateUserAgreesToTracking(false)

            AnalyticsService.stop()
        })

        present(ac, animated: true)
    }

}
