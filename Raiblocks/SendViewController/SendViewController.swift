//
//  SendViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 12/7/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import AVFoundation
import UIKit
import LocalAuthentication
import MobileCoreServices

import Cartography
import Crashlytics
import ReactiveSwift
import Result
import SwiftWebSocket


protocol SendViewControllerDelegate: class {
    func didFinishWithViewController()
}


final class SendViewController: UIViewController {

    private let (lifetime, token) = Lifetime.make()

    private weak var addressTextView: SendAddressTextView?

    private let sendAddressIsValid = MutableProperty<Bool>(false)
    private let sendableAmountIsValid = MutableProperty<Bool>(false)

    private let viewModel: SendViewModel
    private let codeScanViewController: CodeScanViewController = CodeScanViewController()

    private weak var nanoTextField: SendTextField?
    private weak var localCurrencyTextField: SendTextField?
    private weak var activeTextField: UITextField?
    private weak var sendButton: NanoButton?

    private var isScanningAmount: Bool = false

    weak var delegate: SendViewControllerDelegate?

    let (nanoSignal, nanoObserver) = Signal<KeyboardButton, NoError>.pipe()
    let (localCurrencySignal, localCurrencyObserver) = Signal<KeyboardButton, NoError>.pipe()
    let nanoProducer: SignalProducer<KeyboardButton, NoError>
    let localCurrencyProducer: SignalProducer<KeyboardButton, NoError>

    init(viewModel: SendViewModel) {
        self.viewModel = viewModel
        self.nanoProducer = SignalProducer(nanoSignal)
        self.localCurrencyProducer = SignalProducer(localCurrencySignal)

        super.init(nibName: nil, bundle: nil)

        Answers.logCustomEvent(withName: "Send VC Viewed")

        SignalProducer.combineLatest(sendAddressIsValid.producer, sendableAmountIsValid.producer)
            .producer
            .take(during: lifetime)
            .observe(on: UIScheduler())
            .startWithValues {
                self.sendButton?.isEnabled = ($0 && $1)
            }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        self.navigationController?.navigationBar.barTintColor = Styleguide.Colors.darkBlue.color
        self.navigationController?.navigationBar.tintColor = Styleguide.Colors.lightBlue.color

        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: Styleguide.Colors.lightBlue.color,
            .font: Styleguide.Fonts.sofiaRegular.font(ofSize: 16),
            .kern: 5.0
        ]

        self.navigationItem.titleView = SendReceiveHeaderView(withType: .send)
        self.navigationItem.title = "Send To".uppercased()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "camera"), style: .plain, target: self, action: #selector(openCamera))

        let addressTextView = SendAddressTextView()
        addressTextView.delegate = self
        addressTextView.inputAccessoryView = keyboardAccessoryView()
        addressTextView.placeholder = "Enter a Nano Address"
        view.addSubview(addressTextView)
        constrain(addressTextView) {
            $0.top == $0.superview!.top
            $0.left == $0.superview!.left
            $0.right == $0.superview!.right
            $0.height == CGFloat(88)
        }
        self.addressTextView = addressTextView

        // MARK: - Price Section

        let priceSection = UIView()
        priceSection.backgroundColor = Styleguide.Colors.lightBlue.color
        view.addSubview(priceSection)
        constrain(priceSection, addressTextView) {
            $0.width == $0.superview!.width
            $0.top == $1.bottom
            $0.height == (isiPhoneSE() ? CGFloat(100) : CGFloat(140))
        }

        let nanoTextField = SendTextField()
        nanoTextField.delegate = self
        nanoTextField.textAlignment = .center
        priceSection.addSubview(nanoTextField)
        constrain(nanoTextField) {
            $0.top == $0.superview!.top
            $0.height == $0.superview!.height * CGFloat(0.5)
            $0.width == $0.superview!.width
        }
        self.nanoTextField = nanoTextField

        let maxButton = UIButton()
        maxButton.addTarget(self, action: #selector(fillOutWithMaxBalance), for: .touchUpInside)
        view.addSubview(maxButton)
        maxButton.layer.cornerRadius = 3
        maxButton.clipsToBounds = true
        maxButton.setBackgroundColor(color: UIColor.white.withAlphaComponent(0.2), forState: .normal)
        maxButton.setBackgroundColor(color: UIColor.white.withAlphaComponent(0.3), forState: .highlighted)
        let title = NSMutableAttributedString(string: "MAX")
        title.addAttribute(.kern, value: 3.0, range: NSMakeRange(0, title.length))
        title.addAttribute(.foregroundColor, value: UIColor.white, range: NSMakeRange(0, title.length))
        maxButton.titleLabel?.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 14)
        maxButton.setAttributedTitle(title, for: .normal)
        maxButton.titleLabel?.textAlignment = .center
        maxButton.titleLabel?.numberOfLines = 1
        maxButton.titleLabel?.baselineAdjustment = .alignCenters
        constrain(maxButton, nanoTextField) {
            $0.centerY == $1.centerY
            $0.left == $0.superview!.left + CGFloat(20)
            $0.width == CGFloat(58)
            $0.height == CGFloat(29)
        }

        let border = UIView()
        border.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        priceSection.addSubview(border)
        constrain(border) {
            $0.height == CGFloat(1)
            $0.centerY == $0.superview!.centerY
            $0.width == $0.superview!.width
        }

        let upDownArrow = UIImageView(image: UIImage(named: "upDownArrow"))
        priceSection.addSubview(upDownArrow)
        constrain(upDownArrow, border) {
            $0.center == $1.center
        }

        let localCurrencyTextField = SendTextField()
        localCurrencyTextField.delegate = self
        priceSection.addSubview(localCurrencyTextField)
        constrain(localCurrencyTextField, nanoTextField) {
            $0.top == $1.bottom
            $0.bottom == $0.superview!.bottom
            $0.width == $0.superview!.width
            $0.height == $0.superview!.height * CGFloat(0.5)
        }
        self.localCurrencyTextField = localCurrencyTextField

        // MARK: - Bottom Section

        let bottomSection = UIView()
        bottomSection.backgroundColor = Styleguide.Colors.darkBlue.color
        view.addSubview(bottomSection)
        constrain(bottomSection, priceSection) {
            $0.width == $1.width
            $0.centerX == $0.superview!.centerX
            $0.top == $1.bottom
            $0.bottom == $0.superview!.bottom
        }

        let sendButton = NanoButton(withType: .lightBlueSend)
        sendButton.setAttributedTitle("SEND")
        sendButton.addTarget(self, action: #selector(sendNano), for: .touchUpInside)
        sendButton.isEnabled = false
        bottomSection.addSubview(sendButton)
        constrain(sendButton) {
            $0.width == $0.superview!.width * CGFloat(0.8)
            $0.centerX == $0.superview!.centerX
            $0.height == CGFloat(55)
            $0.bottom == $0.superview!.bottom - CGFloat((isiPhoneX() ? 34 : 20))
        }
        self.sendButton = sendButton

        let keyboard = SendKeyboard()
        keyboard.delegate = self
        bottomSection.addSubview(keyboard)
        constrain(keyboard, priceSection, sendButton) {
            $0.top == $1.bottom + (isiPhoneSE() ? CGFloat(9) : CGFloat(36))
            $0.bottom == $2.top - (isiPhoneSE() ? CGFloat(9) : CGFloat(36))
            $0.width == $0.superview!.width * CGFloat(0.8)
            $0.centerX == $0.superview!.centerX
        }

        // Refactor all of this to be more functional
        nanoProducer.producer.startWithValues { button in
            guard
                let textField = self.nanoTextField,
                let text = textField.text
            else { return }

            switch button {
            case .backspace:
                self.viewModel.maxAmountInUse = false

                // TODO: add case: if second to last char is decimalSeparator, deleteBackwardsx2 (see also in other producer below)
                if textField.text! == "0\(self.viewModel.decimalSeparator)" {
                    textField.deleteBackward()
                    textField.deleteBackward()
                } else {
                    textField.deleteBackward()
                }
            case .number:
                if textField.text! == "", button.valueIsDecimalIndicator {
                    textField.text!.insert("0", at: String.Index(encodedOffset: 0))
                    textField.text!.insert(Character(self.viewModel.decimalSeparator), at: String.Index(encodedOffset: 1))
                } else {
                    textField.text!.insert(button.characterValue, at: String.Index(encodedOffset: text.count))
                }
            }

            let value = NSDecimalNumber(string: (textField.text == "" ? "0" : self.formatForMath(textField.text!)))

            // If the value you typed is equal to your total balance
            if value.asRawValue.compare(self.viewModel.sendableNanoBalance) == .orderedSame {
                self.sendableAmountIsValid.value = true

                return self.viewModel.nanoAmount.value = value
            }
            self.viewModel.maxAmountInUse = false

            // If the value you typed is too large
            if value.asRawValue.compare(self.viewModel.sendableNanoBalance) == .orderedDescending {
                return self.fillOutWithMaxBalance(showAlert: true)
            }

            self.sendableAmountIsValid.value = textField.text != ""

            self.viewModel.nanoAmount.value = value
        }

        localCurrencyProducer.producer.startWithValues { button in
            guard
                let textField = self.localCurrencyTextField,
                let text = textField.text
            else { return }

            switch button {
            case .backspace:
                self.viewModel.maxAmountInUse = false

                if textField.text! == "0\(self.viewModel.decimalSeparator)" {
                    textField.deleteBackward()
                    textField.deleteBackward()
                } else {
                    textField.deleteBackward()
                }
            case .number:
                if textField.text! == "\(self.viewModel.localCurrency.mark)", button.valueIsDecimalIndicator {
                    textField.text!.insert("0", at: String.Index(encodedOffset: textField.text!.count))
                    textField.text!.insert(Character(self.viewModel.decimalSeparator), at: String.Index(encodedOffset: textField.text!.count))
                } else {
                    textField.text!.insert(button.characterValue, at: String.Index(encodedOffset: text.count))
                }
            }

            guard let updatedText = textField.text else {
                return self.viewModel.localCurrencyAmount.value = 0.0
            }

            var string = updatedText

            // Remove currency mark
            for _ in 0..<self.viewModel.localCurrency.mark.count {
                string.remove(at: string.startIndex)
            }

            string = self.formatForMath(string)

            self.sendableAmountIsValid.value = textField.text != "\(self.viewModel.localCurrency.mark)"

            self.viewModel.localCurrencyAmount.value = NSDecimalNumber(string: string == "" ? "0" : string)
        }

        viewModel.nanoAmount.producer.startWithValues { amount in
            // TODO: fix case where local currency amount is selected, you scan a code with an amount and the translated amount isn't present
            if self.activeTextField == self.nanoTextField || self.activeTextField == nil {
                self.localCurrencyTextField?.text = self.convertNanoToLocalCurrency(value: amount) ?? "0\(self.viewModel.decimalSeparator)0"
            }
        }

        viewModel.localCurrencyAmount.producer.startWithValues { amount in
            if self.activeTextField == self.localCurrencyTextField {
                let lastTradePrice = NSDecimalNumber(value: self.viewModel.priceService.lastNanoLocalCurrencyPrice.value)

                // If there is an error with the PriceService
                guard lastTradePrice.compare(0) == .orderedDescending else {
                    self.nanoTextField?.text = "Error Getting Nano Price"
                    self.sendableAmountIsValid.value = false

                    // TODO: make this more apparent to the user with online/offline UI states
                    return
                }

                let dividedAmount = amount.dividing(by: lastTradePrice)
                let raw = dividedAmount.asRawValue

                if raw.compare(self.viewModel.sendableNanoBalance) == .orderedDescending {
                    self.fillOutWithMaxBalance(showAlert: true)
                } else {
                    let numberHandler = NSDecimalNumberHandler(roundingMode: .plain, scale: 2, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)

                    let roundedAmount = dividedAmount.rounding(accordingToBehavior: numberHandler)
                    self.viewModel.nanoAmount.value = roundedAmount
                    self.nanoTextField?.text = roundedAmount    .stringValue
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func formatForMath(_ string: String) -> String {
        guard let separator = viewModel.localCurrency.locale.decimalSeparator, separator != "." else { return string }

        return string.replacingOccurrences(of: separator, with: ".")
    }

    func formatForView(_ string: String) -> String {
        guard let separator = viewModel.localCurrency.locale.decimalSeparator else { return string }

        return string.replacingOccurrences(of: ".", with: separator)
    }

    private func convertNanoToLocalCurrency(value: NSDecimalNumber) -> String? {
        var val = value

        // FIXME: implement a better fix for this
        if value.stringValue.contains("0000000") || value.stringValue.count >= 20 {
            val = NSDecimalNumber(string: value.rawAsUsableString)
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = viewModel.localCurrency.locale

        let amount = val.doubleValue * viewModel.priceService.lastNanoLocalCurrencyPrice.value
        return numberFormatter.string(from: NSNumber(floatLiteral: amount))
    }

    @objc private func fillOutWithMaxBalance(showAlert: Bool = false) {
        nanoTextField?.becomeFirstResponder()
        activeTextField = nanoTextField
        nanoTextField?.text = viewModel.sendableNanoBalance.rawAsUsableString
        localCurrencyTextField?.text = self.convertNanoToLocalCurrency(value: viewModel.sendableNanoBalance) ?? "0\(self.viewModel.decimalSeparator)0"

        viewModel.nanoAmount.value = viewModel.sendableNanoBalance

        viewModel.maxAmountInUse = true
        Answers.logCustomEvent(withName: "Send: Max Amount Used")

        if activeTextField == nil {
            self.addressTextView?.resignFirstResponder()
            localCurrencyTextField?.setSmallerFontSize()
        }

        self.sendableAmountIsValid.value = true

        if showAlert {
            self.viewModel.maxAmountInUse = true

            let ac = UIAlertController(title: "Amount Too Large", message: "The amount you entered was larger than your Nano balance.\n\nWe've filled the form with your full balance.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(ac, animated: true, completion: nil)
        }
    }

    @objc func openCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    Answers.logCustomEvent(withName: "Address Scan Camera View Viewed")

                    self.codeScanViewController.delegate = self

                    self.navigationController?.present(self.codeScanViewController, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Camera Permissions Required", message: "Please enable Camera permissions in iOS Settings", preferredStyle: .actionSheet)
                    ac.addAction(UIAlertAction(title: "Okay", style: .default))

                    self.present(ac, animated: true, completion: nil)
                }
            }
        }
    }

    @objc func sendNano() {
        Answers.logCustomEvent(withName: "Send Nano Began")
        // TODO: make address show error
        guard
            let textView = addressTextView,
            let address = Address(textView.attributedText.string),
            let work = viewModel.work
        else { return }

        let subtractor: NSDecimalNumber
        let remainingBalance: NSDecimalNumber
        if viewModel.maxAmountInUse {
            subtractor = viewModel.sendableNanoBalance
            remainingBalance = 0
        } else {
            subtractor = viewModel.nanoAmount.value.asRawValue
            remainingBalance = viewModel.sendableNanoBalance.subtracting(subtractor)
        }

        let endpoint = Endpoint.createSendBlock(
            destination: address,
            balanceHex: viewModel.hexify(balance: remainingBalance),
            previous: viewModel.previousFrontierHash,
            work: work,
            privateKey: viewModel.privateKeyData
        )

        authenticateAndSend(endpoint: endpoint, amountYoullSend: subtractor)
    }

    private func authenticateAndSend(endpoint: Endpoint, amountYoullSend: NSDecimalNumber) {
        guard let amount = amountYoullSend.rawAsLongerUsableString else {
            self.showError(title: "Something went wrong.", message: "There was a problem sending Nano. Please try again.")

            Crashlytics.sharedInstance().recordError(NanoWalletError.longUsableStringCastFailed)

            return
        }

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.appBackgroundingForSeedOrSend = true

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Send \(amount) Nano?"

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [unowned self] success, error in
                DispatchQueue.main.async {
                    guard success else {
                        guard let error = error else {
                            Answers.logCustomEvent(withName: "Error with Send Authentication", customAttributes: ["description": "Generic error"])

                            return self.showError(title: "There was a problem", message: "Please try again.")
                        }

                        Answers.logCustomEvent(withName: "Error with Send Authentication", customAttributes: ["description": error.localizedDescription])

                        switch error {
                        case LAError.userCancel: return
                        case LAError.biometryLockout:
                            return self.showError(title: "Too Many Tries", message: "There were too many failed attempts. Please try your passcode.")
                        case LAError.biometryNotAvailable:
                            return self.showError(title: "Uh oh", message: "FaceID/TouchID are not available on your device.")
                        case LAError.biometryNotEnrolled:
                            return self.showError(title: "There was a problem", message: "Please add your face for FaceID or a fingerprint for TouchID.")
                        case LAError.authenticationFailed:
                            return self.showError(title: "There was a problem", message: "Please try again.")
                        case LAError.passcodeNotSet:
                            return self.showError(title: "Passcode Not Set", message: "Please set a passcode for your phone to send Nano (and for security reasons, in general).")
                        default:
                            return self.showError(title: "There was a problem", message: "Please try again.")
                        }
                    }

                    self.viewModel.socket.send(endpoint: endpoint)
                    self.viewModel.maxAmountInUse = false

                    Answers.logCustomEvent(withName: "Send Nano Finished")

                    appDelegate.appBackgroundingForSeedOrSend = false
                    self.delegate?.didFinishWithViewController()
                }
            }
        } else {
            showError(title: "Authentication Not Available", message: "Please set your iOS device up with a password, TouchID, or FaceID.")
        }
    }

    private func showError(title: String, message: String, buttonText text: String = "Okay") {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.appBackgroundingForSeedOrSend = false

        let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: text, style: .default))

        present(ac, animated: true)
    }

    private func keyboardAccessoryView() -> UIToolbar {
        let accessoryView = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
        accessoryView.barStyle = .default
        let xrbItem = UIBarButtonItem(title: "xrb_", style: .plain, target: self, action: #selector(addXRBAddressPrefix))
        [xrbItem].forEach { $0.tintColor = .black }
        accessoryView.items = [xrbItem]
        accessoryView.sizeToFit()

        return accessoryView
    }

    @objc func addXRBAddressPrefix() {
        Answers.logCustomEvent(withName: "User used xrb_ prefix")

        guard let text = self.addressTextView?.text, !text.contains("_") else { return }

        self.addressTextView?.togglePlaceholder(show: false)
        self.addressTextView?.attributedText = handleRegularTextEntry(forAttributedText: "xrb_")
    }

}

extension SendViewController: CodeScanViewControllerDelegate {

    func didReceiveAddress(address: Address, amount: Double) {
        self.sendAddressIsValid.value = true
        self.isScanningAmount = true
        self.addressTextView?.togglePlaceholder(show: false)
        self.addressTextView?.attributedText = addAttributes(forAttributedText: address.longAddressWithColor)

        if amount > 0 {
            self.nanoTextField?.text = "\(amount)"
            viewModel.nanoAmount.value = NSDecimalNumber(floatLiteral: amount)
        }

        navigationController?.dismiss(animated: true) {
            self.nanoTextField?.becomeFirstResponder()
        }
    }

}


extension SendViewController: UITextViewDelegate {
    // These are virtually the same 2 functions. Refactor
    private func addAttributes(forAttributedText text: NSAttributedString) -> NSAttributedString {
        let str = NSMutableAttributedString(attributedString: text)
        let range = NSMakeRange(0, str.length)
        str.addAttribute(.font, value: Styleguide.Fonts.nunitoRegular.font(ofSize: (isiPhoneSE() ? 15 : 16)), range: range)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        str.addAttribute(.paragraphStyle, value: paragraph, range: range)

        return str
    }

    private func handleRegularTextEntry(forAttributedText text: String) -> NSAttributedString {
        let str = NSMutableAttributedString(string: text)
        let range = NSMakeRange(0, str.length)
        str.addAttribute(.font, value: Styleguide.Fonts.nunitoRegular.font(ofSize: (isiPhoneSE() ? 15 : 16)), range: range)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        str.addAttribute(.paragraphStyle, value: paragraph, range: range)

        return str
    }

    func textViewDidChange(_ textView: UITextView) {
        if let address = Address(textView.text) {
            textView.text = ""

            textView.attributedText = addAttributes(forAttributedText: address.longAddressWithColor)

            self.sendAddressIsValid.value = true
            // TODO: make sure address is not mine too
        } else {
            self.sendAddressIsValid.value = false
            textView.attributedText = handleRegularTextEntry(forAttributedText: textView.text)
        }
    }

    // Allow any A-Z,0-9 character through for the seed as well as backspaces, prevent everything else
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let isBackspace = strcmp(text.cString(using: .utf8)!, "\\b") == -92
        if sendAddressIsValid.value { return isBackspace } // Only allow backspaces on already valid address

        // if you paste in an address
        if text.count > 60 {
            self.addressTextView?.togglePlaceholder(show: false)

            if let _ = Address(text) {
                self.addressTextView?.resignFirstResponder()
            }

            return true
        }

        // Done key
        guard text != "\n" else {
            textView.resignFirstResponder()

            return true
        }

        guard !isBackspace else {
            if textView.text.count == 1 {
                self.addressTextView?.togglePlaceholder(show: true)
            }

            return true
        }

        let validCharacters = ["a","b","c","d","e","f","g","h","i","j","k","m","n","o","p","q","r","s","t","u","w","x","y","z","1","3","4","5","6","7","8","9", "_"]

        let isValidCharacter = validCharacters.contains(text.lowercased())
        if self.addressTextView!.text.count >= 0, isValidCharacter {
            self.addressTextView?.togglePlaceholder(show: false)
        } else {
            return false
        }

        return isValidCharacter
    }

}


/// Used for the Nano and local currency price text fields
extension SendViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let textField = textField as? SendTextField else { return }
        self.activeTextField = textField

        // This guard makes sure that fields aren't zeroed out after the alert shows when you enter over your max balance
        guard !viewModel.maxAmountInUse else  {
            return viewModel.maxAmountInUse = false
        }

        if !self.isScanningAmount {
            nanoTextField?.text = nil
            localCurrencyTextField?.text = viewModel.localCurrency.mark

            viewModel.nanoAmount.value = 0
            viewModel.localCurrencyAmount.value = 0
        }

        if activeTextField == nanoTextField {
            nanoTextField?.setLargerFontSize()
            localCurrencyTextField?.setSmallerFontSize()
        } else {
            localCurrencyTextField?.setLargerFontSize()
            nanoTextField?.setSmallerFontSize()
        }

        self.isScanningAmount = false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        guard string.count == 1 else { return false }

        if text == viewModel.localCurrency.mark && range.length == 1 && string == "<" { return false }

        // handle backspace, NOTE: this needs to come after line above to prevent the user from removing the $
        if string == "<" { return true }

        let separator = viewModel.decimalSeparator
        if text.contains(separator), string == separator { return false }

        if text == "0" && string != separator { return false } // Don't allow 000

        return true
    }

}


extension SendViewController: SendKeyboardDelegate {

    func valueWasSent(button: KeyboardButton) {
        // If the user types without a field explicitly selected
        if activeTextField == nil {
            activeTextField = nanoTextField
            nanoTextField?.becomeFirstResponder()
        }

        guard
            let textField = activeTextField,
            let selectedTextRange = textField.selectedTextRange,
            let delegate = textField.delegate
        else { return }

        let range = NSMakeRange(selectedTextRange.end.hash, 1)
        if delegate.textField!(textField, shouldChangeCharactersIn: range, replacementString: button.stringValue) {

            if self.activeTextField == nanoTextField {
                self.nanoObserver.send(value: button)
            } else {
                self.localCurrencyObserver.send(value: button)
            }
        }
    }

}
