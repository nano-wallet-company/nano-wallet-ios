//
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import UIKit
import LocalAuthentication
import MobileCoreServices
import Cartography

final class SettingsButton: UIButton {

    init() {
        super.init(frame: .zero)

        titleLabel?.textAlignment = .center
        titleLabel?.font = Styleguide.Fonts.notoSansRegular.font(ofSize: 18)
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

    private let userService = UserService()
    private let currencyService = CurrencyService()

    private let currencies: [Currency] = Currency.allCurrencies
    private let localCurrency: Currency

    private weak var pickerView: UIPickerView?
    private var pickerViewHeightLayoutConstraint: NSLayoutConstraint?

    private weak var localCurrencyButton: SettingsButton?

    weak var delegate: SettingsViewControllerDelegate?

    init(localCurrency: Currency) {
        self.localCurrency = localCurrency
        super.init(nibName: nil, bundle: nil)

        AnalyticsEvent.settingsViewed.track()
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
            .font: Styleguide.Fonts.notoSansRegular.font(ofSize: 17),
            .kern: 5.0
        ]

        self.navigationItem.title = "Settings".uppercased()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "dismissBlack"), style: .plain, target: self, action: #selector(dismissVC))

        let localCurrencyButton = SettingsButton()
        localCurrencyButton.setTitle("Show My Local Currency", for: .normal)
        localCurrencyButton.addTarget(self, action: #selector(selectLocalCurrency), for: .touchUpInside)
        view.addSubview(localCurrencyButton)
        constrain(localCurrencyButton) {
            $0.width == $0.superview!.width
            $0.height == CGFloat(66)
            $0.top == $0.superview!.top + (isiPhoneX() ? CGFloat(91) : CGFloat(64))
        }
        self.localCurrencyButton = localCurrencyButton

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

        let viewOnExplorerButton = SettingsButton()
        viewOnExplorerButton.setTitle("View Account on Explorer", for: .normal)
        viewOnExplorerButton.addTarget(self, action: #selector(viewOnExplorer(_:)), for: .touchUpInside)
        view.addSubview(viewOnExplorerButton)
        constrain(viewOnExplorerButton, divider2) {
            $0.width == $1.width
            $0.height == CGFloat(66)
            $0.top == $1.bottom
        }

        let divider4 = UIView()
        divider4.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.addSubview(divider4)
        constrain(divider4, viewOnExplorerButton) {
            $0.height == CGFloat(1)
            $0.width == $1.width
            $0.bottom == $1.bottom
        }

        let readThe = UILabel()
        readThe.text = "Read the"
        readThe.font = Styleguide.Fonts.nunitoLight.font(ofSize: 14)
        readThe.textColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(readThe)
        constrain(readThe, divider4) {
            $0.centerX == $1.centerX - CGFloat(80)
            $0.top == $1.bottom + CGFloat(8)
        }

        let eula = UIButton()
        eula.addTarget(self, action: #selector(viewEula), for: .touchUpInside)
        eula.setTitleColor(Styleguide.Colors.lightBlue.color.withAlphaComponent(0.4), for: .normal)
        eula.setTitleColor(Styleguide.Colors.lightBlue.color.darkerColor(percent: 0.2), for: .normal)
        eula.setTitle("EULA", for: .normal)
        eula.titleLabel?.font = Styleguide.Fonts.nunitoLight.font(ofSize: 14)
        eula.underline()
        view.addSubview(eula)
        constrain(eula, readThe) {
            $0.centerY == $1.centerY
            $0.left == $1.right + CGFloat(4)
        }

        let andLabel = UILabel()
        andLabel.text = "and"
        andLabel.font = Styleguide.Fonts.nunitoLight.font(ofSize: 14)
        andLabel.textColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(andLabel)
        constrain(andLabel, eula) {
            $0.centerY == $1.centerY
            $0.left == $1.right + CGFloat(4)
        }

        let privacyPolicy = UIButton()
        privacyPolicy.addTarget(self, action: #selector(viewPrivacyPolicy), for: .touchUpInside)
        privacyPolicy.setTitleColor(Styleguide.Colors.lightBlue.color.withAlphaComponent(0.4), for: .normal)
        privacyPolicy.setTitleColor(Styleguide.Colors.lightBlue.color.darkerColor(percent: 0.2), for: .normal)
        privacyPolicy.setTitle("Privacy Policy", for: .normal)
        privacyPolicy.titleLabel?.font = Styleguide.Fonts.nunitoLight.font(ofSize: 14)
        privacyPolicy.underline()
        view.addSubview(privacyPolicy)
        constrain(privacyPolicy, andLabel) {
            $0.centerY == $1.centerY
            $0.left == $1.right + CGFloat(4)
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
            $0.top == $1.bottom + CGFloat(28)
            $0.width == $0.superview!.width * CGFloat(0.80)
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
        versionLabel.font = Styleguide.Fonts.notoSansRegular.font(ofSize: 16)
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

        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissVC))
        gestureRecognizer.direction = .down
        view.addGestureRecognizer(gestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func dismissVC() {
        dismiss(animated: true, completion: nil)
    }

    @objc func viewEula() {
        // check if nanowalletcomapny.com will load and if not, load local eula
        Connectivity.shared.getStatus(completion: { status in
            if status == .Reachable{
                self.present(WebViewController(url: URL(string: "https://nanowalletcompany.com/ios-eula")!, useForLegalPurposes: false), animated: true)
            } else {
                let fileUrl = Bundle.main.url(forResource: "ios-eula", withExtension: "html")
                self.present(WebViewController(url: fileUrl!, useForLegalPurposes: false), animated: true)
            }
        })
    }

    @objc func viewPrivacyPolicy() {
        // check if nanowalletcomapny.com will load and if not, load local privacy policy
        Connectivity.shared.getStatus(completion: { status in
            if status == .Reachable{
                self.present(WebViewController(url: URL(string: "https://nanowalletcompany.com/mobile-privacy-policy")!, useForLegalPurposes: false), animated: true)
            } else {
                let fileUrl = Bundle.main.url(forResource: "mobile-privacy-policy", withExtension: "html")
                self.present(WebViewController(url: fileUrl!, useForLegalPurposes: false), animated: true)
            }
        })
    }

    @objc func viewOnExplorer(_ sender: UIButton) {
        guard let address = userService.fetchCredentials()?.address else { return }

        self.present(WebViewController(url: URL(string: "https://nanode.co/search/\(address.longAddress)")!, useForLegalPurposes: false), animated: true)
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
                            AnalyticsEvent.seedCopyFailed.track(customAttributes: ["type": "generic"])
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
                            AnalyticsEvent.seedCopyFailed.track(customAttributes: ["type": error.localizedDescription])

                            let ac = UIAlertController(title: "Authentication failed", message: "Please try again.", preferredStyle: .actionSheet)
                            ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
                                self.dismiss(animated: true, completion: nil)
                            }))
                            self.present(ac, animated: true)

                            return
                        }
                    }

                    AnalyticsEvent.seedCopied.track(customAttributes: ["location": "settings"])

                    let ac = UIAlertController(title: "⚠️ Here is your Wallet Seed, be careful. ⚠️", message: "Tap the button below to copy your Seed to paste later. The Seed is pasteable for 2 minutes and then expires.\n\nWe suggest copying to an app like password management software or printing the Wallet Seed out and hiding it somewhere safe.\n\nNever share your seed with anyone, ever, under any circumstances.", preferredStyle: .actionSheet)
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
            AnalyticsEvent.seedCopyFailed.track()
            appDelegate.appBackgroundingForSeedOrSend = false

            let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Okay", style: .default))
            present(ac, animated: true)
        }
    }

    @objc func selectLocalCurrency() {
        let height: CGFloat = pickerViewHeightLayoutConstraint?.constant == 0 ? 200 : 0
        self.pickerViewHeightLayoutConstraint?.constant = height

        let buttonCopy = height == 0 ? "Show My Local Currency" : "Select Local Currency"
        self.localCurrencyButton?.setTitle(buttonCopy, for: .normal)

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
        completionHandler(userService.fetchCredentials()!.seed.data(using: .utf8), nil)

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

        AnalyticsEvent.localCurrencySelected.track(customAttributes: ["currency": currency.paramValue])

        currencyService.store(currency: StorableCurrency(string: currency.rawValue)!) {
            delegate?.localCurrencyWasSelected(currency: currency)
        }
    }

}
