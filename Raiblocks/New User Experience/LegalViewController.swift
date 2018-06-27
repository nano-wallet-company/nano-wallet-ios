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
            if isiPhoneSE() {
                $0.top == $0.superview!.top + CGFloat(33)
            } else {
                $0.top == $0.superview!.top + CGFloat(44)
            }
            $0.left == $1.left
        }

        let viewCopy = UILabel()
        viewCopy.numberOfLines = 0
        if isiPhonePlus() {
            viewCopy.font = Styleguide.Fonts.nunitoLight.font(ofSize: 18)
        } else if isiPhoneRegular() {
            viewCopy.font = Styleguide.Fonts.nunitoLight.font(ofSize: 16)
        } else {
            viewCopy.font = Styleguide.Fonts.nunitoLight.font(ofSize: 14)
        }
        viewCopy.lineBreakMode = .byWordWrapping
        viewCopy.text = """
        Your use of this Nano Wallet mobile application is subject to your agreement to all terms and conditions of the End User License Agreement and Privacy Policy linked below (collectively, the "Terms and Conditions"). Please tap the links below and read all Terms and Conditions carefully. By checking the boxes below and tapping "I Agree," you acknowledge that you have read, understand and agree to all of the Terms and Conditions, which are binding legal agreements. If you do not understand or agree to any of the Terms and Conditions, you are not licensed or authorized to use this application and should delete it from your device.
        """
        view.addSubview(viewCopy)
        constrain(viewCopy, viewTitle, agreeButton) {
            if isiPhoneSE() {
                $0.top == $1.bottom + CGFloat(10)
            } else {
                $0.top == $1.bottom + CGFloat(20)
            }
            $0.left == $1.left
            $0.right == $2.right
        }

        let eulaCheckbox = createCheckbox()
        view.addSubview(eulaCheckbox)
        constrain(eulaCheckbox, viewCopy) {
            if isiPhoneSE() {
                $0.top == $1.bottom + CGFloat(30)
            } else if isiPhoneRegular() {
                $0.top == $1.bottom + CGFloat(30)
            } else {
                $0.top == $1.bottom + CGFloat(40)
            }
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

        SignalProducer.combineLatest(SignalProducer(eulaCheckbox.reactive.valueChanged), SignalProducer(privacyPolicyCheckbox.reactive.valueChanged))
            .producer
            .take(during: lifetime)
            .observe(on: UIScheduler())
            .startWithValues { _, _ in
                if self.eulaCheckbox?.checkState == .checked &&
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

    @objc func viewEula() {
        AnalyticsEvent.eulaViewed.track(customAttributes: [
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            "date": dateString
        ])
        
        // check if nanowalletcomapny.com will load and if not, load local eula
        if Connectivity.shared.getStatus() == .Reachable{
            let vc = WebViewController(url: URL(string: "https://nanowalletcompany.com/ios-eula")!, useForLegalPurposes: true, agreement: .eula)
            vc.delegate = self
            present(vc, animated: true)
        } else {
            let fileUrl = Bundle.main.url(forResource: "ios-eula", withExtension: "html")
            let vc = WebViewController(url: fileUrl!, useForLegalPurposes: true, agreement: .eula)
            vc.delegate = self
            present(vc, animated: true)
        }
    }

    @objc func viewPrivacyPolicy() {
        AnalyticsEvent.privacyPolicyViewed.track(customAttributes: [
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            "date": dateString
        ])
        
        // check if nanowalletcomapny.com will load and if not, load local privacy policy
        if Connectivity.shared.getStatus() == .Reachable{
            let vc = WebViewController(url: URL(string: "https://nanowalletcompany.com/mobile-privacy-policy")!, useForLegalPurposes: true, agreement: .privacyPolicy)
            vc.delegate = self
            present(vc, animated: true)
        } else {
            let fileUrl = Bundle.main.url(forResource: "mobile-privacy-policy", withExtension: "html")
            let vc = WebViewController(url: fileUrl!, useForLegalPurposes: true, agreement: .privacyPolicy)
            vc.delegate = self
            present(vc, animated: true)
        }
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
        case .eula:
            if self.eulaCheckbox?.checkState == .unchecked {
                self.eulaCheckbox?.toggleAgreement()
            }

        case .privacyPolicy:
            if self.privacyPolicyCheckbox?.checkState == .unchecked {
                self.privacyPolicyCheckbox?.toggleAgreement()
            }
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
