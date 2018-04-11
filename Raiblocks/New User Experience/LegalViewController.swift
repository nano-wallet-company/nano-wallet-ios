//
//  LegalViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 3/22/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

import Foundation

import Cartography
import M13Checkbox
import ReactiveCocoa
import ReactiveSwift
import Result

protocol LegalViewControllerDelegate: class {
    func didFinishWithLegalVC()
}


final class LegalViewController: UIViewController {

    private let useForLoggedInState: Bool
    private let userService = UserService()
    private let credentials: Credentials

    private let dateFormatter = DateFormatter()

    private let (lifetime, token) = Lifetime.make()

    private weak var disclaimerCheckbox: M13Checkbox?
    private weak var eulaCheckbox: M13Checkbox?
    private weak var privacyPolicyCheckbox: M13Checkbox?
    private weak var agreeButton: NanoButton?

    var delegate: LegalViewControllerDelegate?

    private var dateString: String {
        dateFormatter.dateFormat = "MM/dd/yyyy-HH:mm:ssXXX"

        return dateFormatter.string(from: Date())
    }

    init(useForLoggedInState: Bool) {
        self.useForLoggedInState = useForLoggedInState

        guard let credentials = userService.fetchCredentials() else { fatalError("Should always have credentials") }
        self.credentials = credentials

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = .white
        super.viewDidLoad()

        AnalyticsEvent.legalViewed.track()

        let disagreeButton = NanoButton(withType: .grey)
        disagreeButton.addTarget(self, action: #selector(disagreeToLegal), for: .touchUpInside)
        disagreeButton.setAttributedTitle("Disagree")
        view.addSubview(disagreeButton)
        constrain(disagreeButton) {
            $0.bottom == $0.superview!.bottom - (isiPhoneSE() ? CGFloat(17) : CGFloat(34))
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

        Each agreement represents a binding legal agreement and you acknowledge that you have read and agree to the following terms.
        """
        view.addSubview(viewCopy)
        constrain(viewCopy, viewTitle, agreeButton) {
            $0.top == $1.bottom + CGFloat(20)
            $0.left == $1.left
            $0.right == $2.right
        }

        let disclaimerCheckbox = createCheckbox()
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

        // MARK: - Reactive

        SignalProducer(disclaimerCheckbox.reactive.checkboxTapped)
            .producer
            .take(during: lifetime)
            .startWithValues { _ in
                if self.disclaimerCheckbox?.checkState == .checked {
                    self.disclaimerCheckbox?.toggleAgreement()
                }

                self.viewDisclaimer()
        }

        SignalProducer(eulaCheckbox.reactive.checkboxTapped)
            .producer
            .take(during: lifetime)
            .startWithValues { _ in
                if self.eulaCheckbox?.checkState == .checked {
                    self.eulaCheckbox?.toggleAgreement()
                }

                self.viewEula()
        }

        SignalProducer(privacyPolicyCheckbox.reactive.checkboxTapped)
            .producer
            .take(during: lifetime)
            .startWithValues { _ in
                if self.privacyPolicyCheckbox?.checkState == .checked {
                    self.privacyPolicyCheckbox?.toggleAgreement()
                }

                self.viewPrivacyPolicy()
        }

        // MARK: - Reactive For Analytics

        SignalProducer(disclaimerCheckbox.reactive.valueChanged)
            .producer
            .take(during: lifetime)
            .startWithValues { _ in
                guard let checkbox = self.disclaimerCheckbox else { return }

                AnalyticsEvent.disclaimerAgreementToggled.track(customAttributes: [
                    "device_id": UIDevice.current.identifierForVendor!.uuidString,
                    "accepted": checkbox.checkState.rawValue, // 0 = unchecked, 1 = checked
                    "date": self.dateString
                ])
        }

        SignalProducer(eulaCheckbox.reactive.valueChanged)
            .producer
            .take(during: lifetime)
            .startWithValues { _ in
                guard let checkbox = self.eulaCheckbox else { return }

                AnalyticsEvent.eulaAgreementToggled.track(customAttributes: [
                    "device_id": UIDevice.current.identifierForVendor!.uuidString,
                    "accepted": checkbox.checkState.rawValue,
                    "date": self.dateString
                ])
        }

        SignalProducer(privacyPolicyCheckbox.reactive.valueChanged)
            .producer
            .take(during: lifetime)
            .startWithValues { _ in
                guard let checkbox = self.privacyPolicyCheckbox else { return }

                AnalyticsEvent.privacyPolicyAgreementToggled.track(customAttributes: [
                    "device_id": UIDevice.current.identifierForVendor!.uuidString,
                    "accepted": checkbox.checkState.rawValue,
                    "date": self.dateString
                ])
        }

        // MARK: - Master Button Enable/Disable Check

        SignalProducer.combineLatest(SignalProducer(disclaimerCheckbox.reactive.valueChanged), SignalProducer(eulaCheckbox.reactive.valueChanged), SignalProducer(privacyPolicyCheckbox.reactive.valueChanged))
            .producer
            .take(during: lifetime)
            .observe(on: UIScheduler())
            .startWithValues { _, _, _ in
                if self.disclaimerCheckbox?.checkState == .checked &&
                    self.eulaCheckbox?.checkState == .checked &&
                    self.privacyPolicyCheckbox?.checkState == .checked {
                    self.agreeButton?.isEnabled = true
                } else {
                    self.agreeButton?.isEnabled = false
                }
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

    @objc func viewDisclaimer() {
        AnalyticsEvent.disclaimerViewed.track(customAttributes: [
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            "date": dateString
        ])

        let vc = WebViewController(url: URL(string: "https://nanowalletcompany.com/mobile-disclaimer")!, useForLegalPurposes: true, agreement: .disclaimer)
        vc.delegate = self
        present(vc, animated: true)
    }

    @objc func viewEula() {
        AnalyticsEvent.eulaViewed.track(customAttributes: [
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            "date": dateString
        ])

        let vc = WebViewController(url: URL(string: "https://nanowalletcompany.com/mobile-end-user-license-agreement")!, useForLegalPurposes: true, agreement: .eula)
        vc.delegate = self
        present(vc, animated: true)
    }

    @objc func viewPrivacyPolicy() {
        AnalyticsEvent.privacyPolicyViewed.track(customAttributes: [
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            "date": dateString
        ])

        let vc = WebViewController(url: URL(string: "https://nanowalletcompany.com/mobile-privacy-policy")!, useForLegalPurposes: true, agreement: .privacyPolicy)
        vc.delegate = self
        present(vc, animated: true)
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
        userService.updateLegal()

        self.dismiss(animated: true) {
            self.delegate?.didFinishWithLegalVC()
        }
    }

}

extension M13Checkbox {

    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .ended else { return }

        sendActions(for: .touchUpInside)
    }

    func toggleAgreement() {
        toggleCheckState(true)
        sendActions(for: .valueChanged)
    }

}

extension LegalViewController: WebViewControllerDelegate {

    func didDismissWithAcceptance(agreement: Agreement) {
        switch agreement {
        case .disclaimer:
            self.disclaimerCheckbox?.toggleAgreement()

        case .eula:
            self.eulaCheckbox?.toggleAgreement()

        case .privacyPolicy:
            self.privacyPolicyCheckbox?.toggleAgreement()
        }

        dismiss(animated: true, completion: nil)
    }

}


extension Reactive where Base: UIControl {

    public var checkboxTapped: Signal<Void, NoError> {
        return mapControlEvents(.touchUpInside) { _ in }
    }

    public var valueChanged: Signal<Void, NoError> {
        return mapControlEvents(.valueChanged) { _ in }
    }

}
