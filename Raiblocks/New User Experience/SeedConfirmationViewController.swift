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
        titleLabel.text = "Your Nano Wallet Seed".localized()
        titleLabel.textColor = Styleguide.Colors.darkBlue.color
        titleLabel.font = Styleguide.Fonts.nunitoRegular.font(ofSize: 20)
        view.addSubview(titleLabel)
        constrain(titleLabel, logo) {
            $0.centerX == $1.centerX
            $0.top == $1.bottom + CGFloat(20)
        }

        let button = NanoButton(withType: .lightBlue)
        button.addTarget(self, action: #selector(continueButtonWasPressed), for: .touchUpInside)
        button.setAttributedTitle("I Understand, Continue".localized(), withKerning: 0.8)
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
        smallCopy.attributedText = NSAttributedString(string: "Tap to copy".localized(), attributes: [.kern: 1.0])
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
        
        
        let textPart1 = "Your Nano Wallet Seed is a unique code that enables you to access your wallet on the Nano network.\n\nIt is the only way for you to recover your wallet and access any Nano currency you may have.".localized()
        let textPart2 = "We do not have access to it and cannot recover your Wallet Seed or any funds in your wallet without your Wallet Seed.".localized()
        let textPart3 = "You are solely responsible for recording your Wallet Seed in a safe and secure place and manner.".localized()
        let textPart4 = "Never share your Wallet Seed with anyone.".localized()
        
        let text = "\(textPart1)\n\n\(textPart2)\n\n\(textPart3) \(textPart4)"
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttribute(.foregroundColor, value: Styleguide.Colors.darkBlue.color, range: NSMakeRange(0, attributedText.length))
        attributedText.addAttribute(.font, value: Styleguide.Fonts.nunitoRegular.font(ofSize: 16), range: NSMakeRange(0, attributedText.length))

        let textPart2Range = (text as NSString).range(of: textPart2)
        attributedText.addAttribute(.foregroundColor, value: Styleguide.Colors.red.color, range: textPart2Range) // Middle sentence "We do not have access..."
        
        let textPart4Range = (text as NSString).range(of: textPart4)
        attributedText.addAttribute(.foregroundColor, value: Styleguide.Colors.red.color, range: textPart4Range) // last sentence "Never give it..."
        textBody.attributedText = attributedText
        textBody.isScrollEnabled = true
        view.addSubview(textBody)
        constrain(textBody, titleLabel, textView) {
            $0.width == $2.width
            $0.centerX == $0.superview!.centerX

            if isiPhoneSE() {
                $0.top == $1.bottom + CGFloat(22)
                $0.bottom == $2.top - CGFloat(6 )
            } else {
                $0.top == $1.bottom + CGFloat(33)
                $0.bottom == $2.top - CGFloat(16)
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
                let ac = UIAlertController(title: "Wallet Seed Copied".localized(), message: "Your Wallet Seed is pastable for 2 minutes.\nAfter, you can access it in Settings.\n\nPlease backup your Wallet Seed somewhere safe like password management software or print it out and put it in a safe.".localized(), preferredStyle: .actionSheet)
                ac.addAction(UIAlertAction(title: "Okay".localized(), style: .default))

                self.present(ac, animated: true, completion: nil)
            }
        }
    }

    @objc func continueButtonWasPressed() {
        AnalyticsEvent.seedConfirmatonContinueButtonPressed.track()

        let ac = UIAlertController(title: "Welcome to Nano Wallet!".localized(), message: "Please confirm you have properly stored your Wallet Seed somewhere safe.".localized(), preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "I have backed up my Wallet Seed".localized(), style: .default) { _ in
            self.navigationController?.pushViewController(HomeViewController(viewModel: HomeViewModel()), animated: true)
        })
        ac.addAction(UIAlertAction(title: "Back".localized(), style: .cancel))

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
        UserService().updateUserAgreesToTracking(true)
    }

}
