//
//  WelcomeViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 12/15/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import AVFoundation
import UIKit

import Cartography
import Crashlytics


class WelcomeViewController: UIViewController {

    private weak var welcomeTextTopConstraint: NSLayoutConstraint?

    private weak var textFieldHeightConstraint: NSLayoutConstraint?
    private weak var textView: SeedTextView?

    private weak var cameraButtonHeightConstraint: NSLayoutConstraint?
    private weak var cameraButton: UIButton?

    private var keyboardIsVisible: Bool = false
    private var existingSeedWasUsed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        Answers.logCustomEvent(withName: "Welcome VC Viewed")

        view.backgroundColor = .white

        let welcomeLabel = UILabel()
        welcomeLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        welcomeLabel.text = "Welcome to Nano"
        welcomeLabel.textColor = Styleguide.Colors.darkBlue.color
        view.addSubview(welcomeLabel)
        constrain(welcomeLabel) {
            self.welcomeTextTopConstraint = $0.centerY == $0.superview!.centerY
            $0.centerX == $0.superview!.centerX
        }

        let imageView = UIImageView(image: UIImage(named: "largeNanoMarkBlue"))
        view.addSubview(imageView)
        constrain(imageView, welcomeLabel) {
            $0.bottom == $1.top - CGFloat(44)
            $0.centerX == $1.centerX
        }

        let startButton = NanoButton(withType: .lightBlue)
        startButton.setAttributedTitle("Start a new wallet", withKerning: 1)
        startButton.addTarget(self, action: #selector(startANewWallet), for: .touchUpInside)
        view.addSubview(startButton)
        constrain(startButton, welcomeLabel) {
            $0.centerX == $1.centerX
            $0.top == $1.bottom + CGFloat(44)
            $0.width == $0.superview!.width * CGFloat(0.8)
            $0.height == CGFloat(44)
        }

        let existingWalletButton = NanoButton(withType: .lightBlue)
        existingWalletButton.setAttributedTitle("I already have a wallet", withKerning: 1)
        existingWalletButton.addTarget(self, action: #selector(toggleTextFieldForSeed), for: .touchUpInside)
        view.addSubview(existingWalletButton)
        constrain(existingWalletButton, startButton) {
            $0.top == $1.bottom + CGFloat(22)
            $0.centerX == $1.centerX
            $0.width == $0.superview!.width * CGFloat(0.8)
            $0.height == CGFloat(44)
        }

        let textView = SeedTextView()
        textView.delegate = self
        textView.placeholder = "(Tap to Enter Wallet Seed)"
        view.addSubview(textView)
        constrain(textView, existingWalletButton) {
            textFieldHeightConstraint = $0.height == CGFloat(0)
            $0.width == $1.width
            $0.centerX == $1.centerX
            $0.top == $1.top
        }
        self.textView = textView

        let cameraButton = UIButton()
        cameraButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 31, bottom: 0, right: 0) // Align image right
        cameraButton.setImage(UIImage(named: "camera"), for: .normal)
        cameraButton.addTarget(self, action: #selector(showCameraView), for: .touchUpInside)
        view.addSubview(cameraButton)
        constrain(cameraButton, textView) {
            self.cameraButtonHeightConstraint = $0.height == CGFloat(0)
            $0.width == CGFloat(50)
            $0.centerY == $1.centerY
            $0.right == $1.right - CGFloat(16)
        }
        self.cameraButton = cameraButton

        guard
            let dict = Bundle.main.infoDictionary,
            let version = dict["CFBundleShortVersionString"] as? String,
            let build = dict["CFBundleVersion"] as? String
        else { return }

        let versionLabel = UILabel()
        versionLabel.numberOfLines = 2
        versionLabel.textAlignment = .center
        versionLabel.textColor = Styleguide.Colors.lightBlue.color.withAlphaComponent(0.75)
        versionLabel.text =
        """
        NANO
        v \(version) (\(build))
        """
        // set font 14 pt, regular
        view.addSubview(versionLabel)
        constrain(versionLabel) {
            $0.centerX == $0.superview!.centerX
            $0.bottom == $0.superview!.bottom - CGFloat(34)
        }

        let button = UIButton()
        button.addTarget(self, action: #selector(celebrate), for: .touchUpInside)
        view.addSubview(button)
        constrain(button, versionLabel) {
            $0.edges == $1.edges
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        if existingSeedWasUsed {
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
        super.viewWillDisappear(animated)

        view.endEditing(true)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override var prefersStatusBarHidden: Bool { return true }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo, !keyboardIsVisible else { return }

        let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

        // The 20 points gives some breathing room for the camera icon
        welcomeTextTopConstraint?.constant -= view.center.y + 20 - (view.bounds.height - keyboardFrame.height) / 2

        keyboardIsVisible = true

        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        welcomeTextTopConstraint?.constant = 0
        keyboardIsVisible = false

        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func startANewWallet() {
        self.navigationController?.pushViewController(SeedConfirmationViewController(), animated: true)
    }

    @objc func toggleTextFieldForSeed() {
        let shouldShow = self.textFieldHeightConstraint?.constant == 0
        self.textFieldHeightConstraint?.constant = shouldShow ? 80 : 0
        self.cameraButtonHeightConstraint?.constant = shouldShow ? 50 : 0

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            if shouldShow {
                self.textView?.becomeFirstResponder()
            } else {
                self.textView?.text = ""
                self.textView?.togglePlaceholder(show: true)
            }
        }
    }

    @objc func showCameraView() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    Answers.logCustomEvent(withName: "Seed Scan Camera View Viewed")

                    let vc = SeedScanViewController()
                    vc.delegate = self

                    self.present(vc, animated: true)
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

    @objc func celebrate() {
        Answers.logCustomEvent(withName: "Easter Egg Viewed")

        let alertController = UIAlertController(title: "Welcome!", message: "Thank you for using the Nano Mobile Wallet!", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "🎉", style: .default, handler: nil))

        present(alertController, animated: true, completion: nil)
    }

    private func showAlertForBadSeed(message: String? = nil) {
        Answers.logCustomEvent(withName: "Alert for bad seed viewed")

        let ac = UIAlertController(title: "There was a problem with your Wallet Seed", message: message ?? "There was a problem importing your Wallet Seed. Please double check it and try again or contact Nano's support channel.", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

        present(ac, animated: true, completion: nil)
    }

    private func createCredentialsAndContinue(forSeed seed: String) {
        self.existingSeedWasUsed = true

        guard let credentials = Credentials(seedString: seed) else { return }

        UserService().store(credentials: credentials) {
            self.navigationController?.pushViewController(HomeViewController(viewModel: HomeViewModel()), animated: true)
        }
    }
}


extension WelcomeViewController: UITextViewDelegate {

    // Allow any A-Z,0-9 character through for the seed as well as backspaces, prevent everything else
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Pastes an address
        if (Address(text)) != nil || text.contains("_") {
            showAlertForBadSeed(message: "It looks like you've entered a Nano Address rather than a Wallet Seed.\n\nEnter your Wallet Seed to try again.")

            return false
        }

        // Wallet Seed was pasted
        if text.count == 64 {
            // User pasted an address
            if (Address(text) != nil || text.contains("_")) {
                showAlertForBadSeed(message: "It looks like you've entered a Nano Address rather than a Wallet Seed.\n\nEnter your Wallet Seed to try again.")

                return false
            } else {
                createCredentialsAndContinue(forSeed: text.flatten())
            }
        }

        // User entered good Wallet Seed
        if textView.text.count == 63 {
            let seed = textView.text + text
            self.createCredentialsAndContinue(forSeed: seed.flatten())
        }

        guard text != "\n" else {
            textView.resignFirstResponder()

            if text.count == 1 {
                self.toggleTextFieldForSeed()
            }

            return true
        }

        let isBackspace = strcmp(text.cString(using: .utf8)!, "\\b") == -92
        guard !isBackspace else { return true }

        let validCharacters = ["a","b","c","d","e","f","0","1","2","3","4","5","6","7","8","9"]

        let isValidCharacter = validCharacters.contains(text.lowercased())
        if self.textView!.text.count >= 0, isValidCharacter {
            self.textView?.togglePlaceholder(show: false)
        } else {
            return false
        }

        return isValidCharacter
    }

}


extension WelcomeViewController: SeedScanViewControllerDelegate {

    func didReceiveSeedCode(walletSeed: String) {
        if let creds = Credentials(seedString: walletSeed) {
            dismiss(animated: true) {
                self.existingSeedWasUsed = true

                UserService().store(credentials: creds) {
                    self.navigationController?.pushViewController(HomeViewController(viewModel: HomeViewModel()), animated: true)
                }
            }
        } else {
            let alertController = UIAlertController(title: "Uh Oh", message: "Something went wrong scanning your Wallet Seed. Please try again.", preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

            present(alertController, animated: true, completion: nil)
        }
    }

    func seedScanDidCancel() {
        dismiss(animated: true) {
            self.textView?.becomeFirstResponder()
        }
    }

}
