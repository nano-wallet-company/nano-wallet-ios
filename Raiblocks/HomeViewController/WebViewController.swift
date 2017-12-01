//
//  WebViewController.swift
//  Raiblocks
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

import UIKit
import WebKit

import Cartography


class WebViewController: UIViewController {

    private let url: URL
    private weak var progressBar: UIProgressView?

    init(url: URL) {
        self.url = url
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
            toolbar.top == toolbar.superview!.top
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

        let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeWebview))
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
        self.view.addSubview(webView)
        constrain(webView, toolbar) { view, toolbar in
            view.top == toolbar.bottom
            view.left == view.superview!.left
            view.right == view.superview!.right
            view.bottom == view.superview!.bottom
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    @objc func closeWebview() {
        dismiss(animated: true, completion: nil)
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

