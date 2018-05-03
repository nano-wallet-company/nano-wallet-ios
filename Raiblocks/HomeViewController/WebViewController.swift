//
//  WebViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import UIKit
import WebKit

import Cartography


protocol WebViewControllerDelegate: class {
    func didDismissWithAcceptance(agreement: Agreement)
}

enum Agreement {
    case disclaimer, eula, privacyPolicy
}

// TODO: Subclass
class WebViewController: UIViewController {

    private let url: URL
    private let useForLegal: Bool
    private let legalAgreement: Agreement?
    private weak var progressBar: UIProgressView?
    private weak var acceptButton: NanoButton?

    var delegate: WebViewControllerDelegate?

    init(url: URL, useForLegalPurposes: Bool, agreement: Agreement? = nil) {
        self.url = url
        self.useForLegal = useForLegalPurposes
        self.legalAgreement = agreement
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let toolbar = UIToolbar()
        view.addSubview(toolbar)
        constrain(toolbar) { toolbar in
            toolbar.width == toolbar.superview!.width
            toolbar.centerX == toolbar.superview!.centerX
            toolbar.top == toolbar.superview!.top + (isiPhoneX() ? CGFloat(11) : CGFloat(0))
            toolbar.height == CGFloat(64)
        }

        let progressBar = UIProgressView(progressViewStyle: .bar)
        progressBar.backgroundColor = .clear
        progressBar.tintColor = Styleguide.Colors.darkBlue.color
        toolbar.addSubview(progressBar)
        constrain(progressBar, toolbar) { progress, toolbar in
            progress.width == toolbar.width
            progress.height == CGFloat(2)
            progress.bottom == toolbar.bottom
            progress.centerX == toolbar.centerX
        }
        self.progressBar = progressBar

        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let closeButtonTitle = useForLegal ? "Cancel" : "Done"
        let closeButton = UIBarButtonItem(title: closeButtonTitle, style: .done, target: self, action: #selector(closeWebview))
        closeButton.tintColor = Styleguide.Colors.darkBlue.color

        toolbar.setItems([flex, closeButton], animated: true)
        toolbar.barTintColor = .white
        toolbar.barStyle = .blackTranslucent

        let borderView = UIView()
        borderView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        toolbar.addSubview(borderView)
        constrain(borderView) { borderView in
            borderView.height == CGFloat(0.5)
            borderView.width == borderView.superview!.width
            borderView.centerX == borderView.superview!.centerX
            borderView.bottom == borderView.superview!.bottom
        }

        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
        webView.scrollView.delegate = self
        webView.scrollView.bounces = false
        self.view.addSubview(webView)

        if useForLegal {
            let acceptButton = NanoButton(withType: .lightBlueSend)
            acceptButton.setAttributedTitle("I Accept")
            acceptButton.addTarget(self, action: #selector(agreeToLegalAgreement), for: .touchUpInside)
            acceptButton.isEnabled = false
            view.addSubview(acceptButton)
            constrain(acceptButton) {
                $0.bottom == $0.superview!.bottom - CGFloat(34)
                $0.centerX == $0.superview!.centerX
                $0.width == $0.superview!.width * CGFloat(0.8)
                $0.height == CGFloat(55)
            }
            self.acceptButton = acceptButton

            constrain(webView, acceptButton, toolbar) { view, button, toolbar in
                view.top == toolbar.bottom
                view.left == view.superview!.left
                view.right == view.superview!.right
                view.bottom == button.top - CGFloat(34)
            }
        } else {
            constrain(webView, toolbar) { view, toolbar in
                view.top == toolbar.bottom
                view.left == view.superview!.left
                view.right == view.superview!.right
                view.bottom == view.superview!.bottom
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func closeWebview() {
        dismiss(animated: true, completion: nil)
    }

    @objc func agreeToLegalAgreement() {
        guard let agreement = legalAgreement else { return }

        delegate?.didDismissWithAcceptance(agreement: agreement)
    }

}

extension WebViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Guards against content size when loading
        guard scrollView.contentSize.height > 0.0 else { return }

        self.acceptButton?.isEnabled = (scrollView.contentOffset.y + 40 >= (scrollView.contentSize.height - scrollView.frame.size.height))
    }

}


extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressBar?.setProgress(0, animated: false)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.progressBar?.isHidden = true
        }) { _ in
            self.progressBar?.isHidden = false
            self.progressBar?.setProgress(0, animated: false)
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        progressBar?.setProgress(1, animated: true)
    }

    func webView(webView: WKWebView, navigation: WKNavigation, withError error: NSError) {
        progressBar?.setProgress(1, animated: true)

        let alertController = UIAlertController(title: "Error", message: "Could not load url", preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay", style: .cancel) { _ in self.closeWebview() }
        alertController.addAction(action)

        present(alertController, animated: true, completion: nil)
    }

    private func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        return decisionHandler(.allow)
    }

}
