//
//  SeedConfirmationViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 1/19/18.
//  Copyright © 2018 Nano. All rights reserved.
//

import UIKit
import LocalAuthentication
import MobileCoreServices

import Cartography
import Crashlytics


class SeedConfirmationViewController: UIViewController {

    private var credentials: Credentials
    private var seedWasCopied = false

    private weak var textView: UITextView?

    init() {
        guard let credentials = Credentials(seed: RaiCore().createSeed()) else {
            Crashlytics.sharedInstance().recordCustomExceptionName("Credential Creation Failed", reason: nil, frameArray: [])

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

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Answers.logCustomEvent(withName: "Seed Confirmation VC Viewed")

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
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 60, bottom: 12, right: 60)
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
        smallCopy.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 14)
        smallCopy.textColor = Styleguide.Colors.darkBlue.color
        smallCopy.attributedText = NSAttributedString(string: "Tap to copy", attributes: [.kern: 1.0])
        view.addSubview(smallCopy)
        constrain(smallCopy, textView) {
            $0.centerX == $1.centerX
            $0.top == $1.bottom + CGFloat(6)
        }

        let textBody = UITextView()
        textBody.textAlignment = .left
        textBody.isUserInteractionEnabled = false
        let attributedText = NSMutableAttributedString(string: "Your Nano Wallet Seed is how we generate your wallet. It’s also how you log into the iOS Wallet or any of our other wallets, including NanoWallet.io.\n\nIf you lose your Wallet Seed, your funds cannot be recovered.\n\nKeep your Wallet Seed somewhere safe (like 1Password, LastPass, or print it out and put it in a safe).\n\nNever give it to anyone, ever.")
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
            $0.top == $1.bottom + CGFloat(33)
            $0.bottom == $2.top - CGFloat(33)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func copySeed() {
        Answers.logCustomEvent(withName: "Seed Copied", customAttributes: ["location": "seed confirmation"])

        textView?.selectedTextRange = nil

        DispatchQueue.global().async {
            UIPasteboard.general.setObjects([self], localOnly: false, expirationDate: Date().addingTimeInterval(120))

            DispatchQueue.main.sync {
                let ac = UIAlertController(title: "Wallet Seed Copied", message: "Your Wallet Seed is pastable for 2 minutes.\nAfter, you can access it in Settings.\n\nPlease backup your Wallet Seed somewhere safe like 1Password, LastPass, or print it out and put it in a safe.", preferredStyle: .actionSheet)
                ac.addAction(UIAlertAction(title: "Okay", style: .default))

                self.present(ac, animated: true, completion: nil)
            }
        }
    }

    @objc func continueButtonWasPressed() {
        Answers.logCustomEvent(withName: "Seed Confirmation Continue Button Pressed")

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
        completionHandler(credentials.seed.data(using: .utf8), nil)

        return nil
    }

}
