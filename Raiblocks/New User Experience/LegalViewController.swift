//
//  LegalViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 3/22/18.
//  Copyright © 2018 Nano. All rights reserved.
//

import Foundation

import Cartography
import Crashlytics
import M13Checkbox
import ReactiveCocoa
import ReactiveSwift
import Result


final class LegalViewController: UIViewController {

    private let useForLoggedInState: Bool

    private let dateFormatter = DateFormatter()

//    private let (lifetime, token) = Lifetime.make()

    private weak var disclaimerCheckbox: M13Checkbox?
    private weak var eulaCheckbox: M13Checkbox?
    private weak var privacyPolicyCheckbox: M13Checkbox?
    private weak var agreeButton: NanoButton?

    init(useForLoggedInState: Bool) {
        self.useForLoggedInState = useForLoggedInState
        super.init(nibName: nil, bundle: nil)

//        let p1 = SignalProducer(reactive.trigger(for: #selector(disclaimerToggled(_:))))
//
//        p1.producer
//            .take(during: lifetime)
//            .observe(on: UIScheduler()).startWithValues {
//                print("fired")
//        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = .white
        super.viewDidLoad()

        let disagreeButton = NanoButton(withType: .grey)
        disagreeButton.addTarget(self, action: #selector(disagreeToLegal), for: .touchUpInside)
        disagreeButton.setAttributedTitle("Disagree")
        view.addSubview(disagreeButton)
        constrain(disagreeButton) {
            $0.bottom == $0.superview!.bottom - CGFloat(34)
            $0.right == $0.superview!.centerX - CGFloat(10)
            $0.width == $0.superview!.width * CGFloat(0.43)
            $0.height == CGFloat(55)
        }

        let agreeButton = NanoButton(withType: .lightBlue)
        agreeButton.addTarget(self, action: #selector(agreeToLegal), for: .touchUpInside)
        agreeButton.setAttributedTitle("Agree")
        agreeButton.isEnabled = false
        view.addSubview(agreeButton)
        constrain(agreeButton, disagreeButton) {
            $0.bottom == $1.bottom
            $0.left == $0.superview!.centerX + CGFloat(10)
            $0.width == $1.width
            $0.height == $1.height
        }
        self.agreeButton = agreeButton

        let viewTitle = UILabel()
        viewTitle.text = "Terms and Conditions"
        viewTitle.font = Styleguide.Fonts.nunitoRegular.font(ofSize: 24)
        viewTitle.underline()
        view.addSubview(viewTitle)
        constrain(viewTitle, disagreeButton) {
            $0.top == $0.superview!.top + CGFloat(44)
            $0.left == $1.left
        }

        let viewCopy = UILabel()
        viewCopy.numberOfLines = 0
        viewCopy.font = Styleguide.Fonts.nunitoLight.font(ofSize: 20)
        viewCopy.lineBreakMode = .byWordWrapping
        viewCopy.text = """
        Tap the links below and read them carefully.

        By checking the boxes, you acknowledge that you have read and agree to the following terms.
        """
        view.addSubview(viewCopy)
        constrain(viewCopy, viewTitle, agreeButton) {
            $0.top == $1.bottom + CGFloat(20)
            $0.left == $1.left
            $0.right == $2.right
        }

        let disclaimerCheckbox = createCheckbox()
        disclaimerCheckbox.addTarget(self, action: #selector(disclaimerToggled), for: .touchUpInside)
        view.addSubview(disclaimerCheckbox)
        constrain(disclaimerCheckbox, viewCopy) {
            $0.top == $1.bottom + (isiPhoneSE() ? CGFloat(20) : CGFloat(40))
            $0.left == $1.left
            $0.width == (isiPhoneSE() ? CGFloat(30) : CGFloat(40))
            $0.height == (isiPhoneSE() ? CGFloat(30) : CGFloat(40))
        }
        self.disclaimerCheckbox = disclaimerCheckbox

        let disclaimer = createUnderlinedButton()
        disclaimer.setTitle("Mobile Disclaimer", for: .normal)
        disclaimer.addTarget(self, action: #selector(viewDisclaimer), for: .touchUpInside)
        disclaimer.underline()
        view.addSubview(disclaimer)
        constrain(disclaimer, disclaimerCheckbox) {
            $0.bottom == $1.bottom
            $0.left == $1.right + CGFloat(20)
        }

        let eulaCheckbox = createCheckbox()
        eulaCheckbox.addTarget(self, action: #selector(eulaToggled(_:)), for: .touchUpInside)
        view.addSubview(eulaCheckbox)
        constrain(eulaCheckbox, disclaimerCheckbox) {
            $0.top == $1.bottom + CGFloat(40)
            $0.left == $1.left
            $0.width == (isiPhoneSE() ? CGFloat(30) : CGFloat(40))
            $0.height == (isiPhoneSE() ? CGFloat(30) : CGFloat(40))
        }
        self.eulaCheckbox = eulaCheckbox

        let eula = createUnderlinedButton()
        eula.setTitle("End User License Agreement", for: .normal)
        eula.addTarget(self, action: #selector(viewEula), for: .touchUpInside)
        eula.underline()
        view.addSubview(eula)
        constrain(eula, eulaCheckbox) {
            $0.bottom == $1.bottom
            $0.left == $1.right + CGFloat(20)
        }

        let privacyPolicyCheckbox = createCheckbox()
        privacyPolicyCheckbox.addTarget(self, action: #selector(privacyPolicyToggled(_:)), for: .touchUpInside)
        view.addSubview(privacyPolicyCheckbox)
        constrain(privacyPolicyCheckbox, eulaCheckbox) {
            $0.top == $1.bottom + CGFloat(40)
            $0.left == $1.left
            $0.width == (isiPhoneSE() ? CGFloat(30) : CGFloat(40))
            $0.height == (isiPhoneSE() ? CGFloat(30) : CGFloat(40))
        }
        self.privacyPolicyCheckbox = privacyPolicyCheckbox

        let privacyPolicy = createUnderlinedButton()
        privacyPolicy.setTitle("Privacy Policy", for: .normal)
        privacyPolicy.addTarget(self, action: #selector(viewPrivacyPolicy), for: .touchUpInside)
        privacyPolicy.underline()
        view.addSubview(privacyPolicy)
        constrain(privacyPolicy, privacyPolicyCheckbox) {
            $0.bottom == $1.bottom
            $0.left == $1.right + CGFloat(20)
        }

    }

    private func createCheckbox() -> M13Checkbox {
        let checkbox = M13Checkbox()
        checkbox.boxType = .square
        checkbox.markType = .checkmark
        checkbox.boxLineWidth = 2
        checkbox.animationDuration = 0.2
        checkbox.tintColor = Styleguide.Colors.lightBlue.color
        checkbox.secondaryTintColor = Styleguide.Colors.lightBlue.color

        return checkbox
    }

    private func createUnderlinedButton() -> UIButton {
        let button = UIButton()
        button.titleLabel?.font = Styleguide.Fonts.nunitoLight.font(ofSize: (isiPhoneSE() ? CGFloat(18) : CGFloat(22)))
        button.setTitleColor(Styleguide.Colors.darkBlue.color, for: .normal)

        return button
    }

    @objc func disclaimerToggled() {
        dateFormatter.dateFormat = "MM/dd/yyyy-HH:mm:ssXXX"

        Answers.logCustomEvent(withName: "Mobile Disclaimer Agreement Toggled", customAttributes: [
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            "accepted": disclaimerCheckbox?.checkState == .unchecked ? false : true,
            "date": dateFormatter.string(from: Date())
        ])
    }

    @objc func viewDisclaimer() {
        present(WebViewController(url: URL(string: "https://nano.org/mobile-disclaimer")!), animated: true)
    }

    @objc func eulaToggled(_ sender: M13Checkbox) {
        dateFormatter.dateFormat = "MM/dd/yyyy-HH:mm:ssXXX"

        Answers.logCustomEvent(withName: "Mobile EULA Agreement Toggled", customAttributes: [
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            "accepted": eulaCheckbox?.checkState == .unchecked ? false : true,
            "date": dateFormatter.string(from: Date())
        ])
    }

    @objc func viewEula() {
        present(WebViewController(url: URL(string: "https://nano.org/mobile-end-user-license-agreement")!), animated: true)
    }

    @objc func privacyPolicyToggled(_ sender: M13Checkbox) {
        dateFormatter.dateFormat = "MM/dd/yyyy-HH:mm:ssXXX"

        Answers.logCustomEvent(withName: "Mobile Privacy Policy Agreement Toggled", customAttributes: [
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            "accepted": privacyPolicyCheckbox?.checkState == .unchecked ? false : true,
            "date": dateFormatter.string(from: Date())
        ])
    }

    @objc func viewPrivacyPolicy() {
        present(WebViewController(url: URL(string: "https://nano.org/mobile-privacy-policy")!), animated: true)
    }

    @objc func disagreeToLegal() {
        if useForLoggedInState {
            let ac = UIAlertController(title: "Log Out Warning", message: "Not agreeing will result in logging out of the app.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Log Me Out", style: .destructive) { _ in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LogOut"), object: nil)
            })
            ac.addAction(UIAlertAction(title: "Cancel", style: .default))

            present(ac, animated: true)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LogOut"), object: nil)
        }
    }

    @objc func agreeToLegal() {
        // if all 3 are checked,

    }

    // TODO:

    // Enable/disable Agree button based on 3 checkboxes
    // Get check box action working
    // Record legal answer on credential
    // Implement for non-logged in peoples

 }
