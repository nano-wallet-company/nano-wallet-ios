//
//  Copyright © 2017 Nano. All rights reserved.
//

import UIKit
import LocalAuthentication
import MobileCoreServices

import Cartography
import Crashlytics


final class SettingsButton: UIButton {

    init() {
        super.init(frame: .zero)

        titleLabel?.textAlignment = .center
        titleLabel?.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 18)
        titleLabel?.textColor = Styleguide.Colors.darkBlue.color

        setTitleColor(Styleguide.Colors.darkBlue.color, for: .normal)

        setBackgroundColor(color: .white, forState: .normal)
        setBackgroundColor(color: UIColor.black.withAlphaComponent(0.1), forState: .highlighted)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}


protocol SettingsViewControllerDelegate: class {
    func localCurrencyWasSelected(currency: Currency)
}


final class SettingsViewController: UIViewController {

    private let credentials: Credentials
    private let currencyService = CurrencyService()

    private let currencies: [Currency] = Currency.allCurrencies
    private let localCurrency: Currency

    private weak var pickerView: UIPickerView?
    private var pickerViewHeightLayoutConstraint: NSLayoutConstraint?

    weak var delegate: SettingsViewControllerDelegate?

    init(credentials: Credentials, localCurrency: Currency) {
        self.credentials = credentials
        self.localCurrency = localCurrency
        super.init(nibName: nil, bundle: nil)

        Answers.logCustomEvent(withName: "Settings VC Viewed")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        navigationController?.navigationBar.tintColor = Styleguide.Colors.lightBlue.color
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: Styleguide.Colors.darkBlue.color,
            .font: Styleguide.Fonts.sofiaRegular.font(ofSize: 17),
            .kern: 5.0
        ]

        self.navigationItem.title = "Settings".uppercased()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "dismissBlack"), style: .plain, target: self, action: #selector(dismissVC))

        let localCurrencyButton = SettingsButton()
        localCurrencyButton.setTitle("Local Currency", for: .normal)
        localCurrencyButton.addTarget(self, action: #selector(selectLocalCurrency), for: .touchUpInside)
        view.addSubview(localCurrencyButton)
        constrain(localCurrencyButton) {
            $0.width == $0.superview!.width
            $0.height == CGFloat(66)
            $0.top == $0.superview!.top + (isiPhoneX() ? CGFloat(91) : CGFloat(64))
        }

        let divider = UIView()
        divider.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.addSubview(divider)
        constrain(divider, localCurrencyButton) {
            $0.height == CGFloat(1)
            $0.width == $1.width
            $0.bottom == $1.bottom
        }

        let showSeedButton = SettingsButton()
        showSeedButton.setTitle("Copy My Wallet Seed", for: .normal)
        showSeedButton.addTarget(self, action: #selector(showSeed), for: .touchUpInside)
        view.addSubview(showSeedButton)
        constrain(showSeedButton, localCurrencyButton) {
            $0.width == $1.width
            $0.height == $1.height
            $0.top == $1.bottom
        }

        let divider2 = UIView()
        divider2.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.addSubview(divider2)
        constrain(divider2, showSeedButton) {
            $0.height == CGFloat(1)
            $0.width == $1.width
            $0.bottom == $1.bottom
        }

        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.backgroundColor = Styleguide.Colors.lime.color
        picker.tintColor = Styleguide.Colors.darkBlue.color
        picker.layer.cornerRadius = 3
        picker.clipsToBounds = true
        if let index = currencies.index(of: localCurrency) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        view.addSubview(picker)
        constrain(picker, divider2) {
            $0.centerX == $1.centerX
            $0.top == $1.bottom + 22
            $0.width == $0.superview!.width * 0.80
            pickerViewHeightLayoutConstraint = $0.height == 0
        }
        self.pickerView = picker

        let logOutButton = SettingsButton()
        logOutButton.setTitle("Log Out", for: .normal)
        logOutButton.addTarget(self, action: #selector(logOut), for: .touchUpInside)
        view.addSubview(logOutButton)
        constrain(logOutButton,showSeedButton) {
            $0.width == $1.width
            $0.height == $1.height
            $0.bottom == $0.superview!.bottom - (isiPhoneX() ? 34 : 0)
        }

        let divider3 = UIView()
        divider3.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.addSubview(divider3)
        constrain(divider3, logOutButton) {
            $0.height == CGFloat(1)
            $0.width == $1.width
            $0.top == $1.top
        }

        let versionLabel = UILabel()
        versionLabel.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 16)
        versionLabel.textColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(versionLabel)
        constrain(versionLabel, divider3) {
            $0.bottom == $1.top - CGFloat(8)
            $0.centerX == $0.superview!.centerX
        }
        if let dict = Bundle.main.infoDictionary, let version = dict["CFBundleShortVersionString"] as? String,
            let build = dict["CFBundleVersion"] as? String {
            versionLabel.text = "v \(version) (\(build))"
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func dismissVC() {
        dismiss(animated: true, completion: nil)
    }

    func authenticateUser() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.appBackgroundingForSeedOrSend = true

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Verify your identity to view your wallet seed."

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [unowned self] success, error in
                DispatchQueue.main.async {
                    guard success else {
                        guard let error = error else {
                            Answers.logCustomEvent(withName: "Seed Copy Failed", customAttributes: ["type": "generic"])
                            appDelegate.appBackgroundingForSeedOrSend = false

                            let ac = UIAlertController(title: "Authentication failed", message: "Please try again.", preferredStyle: .actionSheet)
                            ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
                                self.dismiss(animated: true, completion: nil)
                            }))

                            self.present(ac, animated: true)

                            return
                        }

                        appDelegate.appBackgroundingForSeedOrSend = false
                        switch error {
                        case LAError.userCancel: return
                        default:
                            Answers.logCustomEvent(withName: "Seed Copy Failed", customAttributes: ["type": error.localizedDescription])

                            let ac = UIAlertController(title: "Authentication failed", message: "Please try again.", preferredStyle: .actionSheet)
                            ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
                                self.dismiss(animated: true, completion: nil)
                            }))
                            self.present(ac, animated: true)

                            return
                        }
                    }

                    Answers.logCustomEvent(withName: "Seed Copied", customAttributes: ["location": "settings"])

                    let ac = UIAlertController(title: "⚠️ Here is your Wallet Seed, be careful. ⚠️", message: "Tap the button below to copy your Seed to paste later. The Seed is pasteable for 2 minutes and then expires.\n\nWe suggest copying to an app like 1Password, LastPass, or printing the Seed out and hiding it somewhere safe.\n\nNever share your seed with anyone, ever, under any circumstances.", preferredStyle: .actionSheet)
                    ac.addAction(UIAlertAction(title: "Copy Seed", style: .default, handler: { _ in
                        appDelegate.appBackgroundingForSeedOrSend = false

                        // you have 2 minutes to paste this or it expires
                        UIPasteboard.general.setObjects([self], localOnly: false, expirationDate: Date().addingTimeInterval(120))
                    }))
                    ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        appDelegate.appBackgroundingForSeedOrSend = false
                    })

                    self.present(ac, animated: true)
                }
            }
        } else {
            Answers.logCustomEvent(withName: "Seed Copy Failed")
            appDelegate.appBackgroundingForSeedOrSend = false

            let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Okay", style: .default))
            present(ac, animated: true)
        }
    }

    @objc func selectLocalCurrency() {
        let val: CGFloat = pickerViewHeightLayoutConstraint?.constant == 0 ? 200 : 0
        self.pickerViewHeightLayoutConstraint?.constant = val

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func showSeed() {
        authenticateUser()
    }

    @objc func logOut() {
        let ac = UIAlertController(title: "Are you sure you want to log out?", message: "Logging out will remove your Wallet Seed, keys and all of your Nano-related data from this device.", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LogOut"), object: nil)
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))

        present(ac, animated: true)
    }

}


extension SettingsViewController: NSItemProviderWriting {

    static var writableTypeIdentifiersForItemProvider: [String] {
        return [kUTTypeUTF8PlainText as String]
    }

    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        completionHandler(credentials.seed.data(using: .utf8), nil)

        return nil
    }

}


extension SettingsViewController: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencies.count
    }

}



extension SettingsViewController: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return currencies[row].nameWithMark
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let currency = currencies[row]

        Answers.logCustomEvent(withName: "Local Currency Selected", customAttributes: ["currency": currency.paramValue])

        currencyService.store(currency: StorableCurrency(string: currency.rawValue)!) {
            delegate?.localCurrencyWasSelected(currency: currency)
        }
    }

}
