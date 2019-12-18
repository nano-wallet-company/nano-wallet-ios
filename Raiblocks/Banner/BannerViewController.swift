//
//  BannerViewController.swift
//  Raiblocks
//
//  Created by Fawaz Tahir on 1/6/19.
//  Copyright © 2019 Zack Shapiro. All rights reserved.
//

import Foundation
import Cartography

class BannerViewController: UIViewController {
    
    var actionHandler: ((URL)->())? = nil {
        didSet {
            bannerView.actionHandler = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.actionHandler?(strongSelf.url)
            }
        }
    }
    
    var minimizeActionHandler: ((Bool)->())? = nil {
        didSet {
            bannerView.minimizeActionHandler = { [weak self] (minimized) in
                guard let strongSelf = self else { return }
                strongSelf.update(for: minimized)
                strongSelf.minimizeActionHandler?(minimized)
            }
        }
    }
    
    let bannerView: BannerView
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        bannerView = BannerView(frame: .zero)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
}

private extension BannerViewController {
    
    func setup() {
        setupConstraints()
        bannerView.actionButton.setAttributedTitle(bannerViewButtonText, withKerning: 1)
        bannerView.minimized = UserDefaults.standard.bool(forKey: persistenceMinimizedKey)
        update(for: bannerView.minimized)
    }
    
    func setupConstraints() {
        view.addSubview(bannerView)
        constrain(bannerView) {
            $0.width == $0.superview!.width
            $0.height == $0.superview!.height
        }
    }
}

private extension BannerViewController {
    
    var url: URL {
        return URL(string: "https://nanowalletcompany.com")!
    }
    
    var bannerViewText: String {
        return "The Nano Wallet Company (NWC) is discontinuing this mobile wallet in favor of other superior wallets developed by the Nano community. On February 10, 2020 the servers will be turned off and this app will no longer be able to send or receive Nano. Please securely copy and store your seed which will keep your Nano safe and allow you to use other wallets to send and receive. Instructions and more details can be found in our official announcement.\n"
    }
    
    var minimizedBannerViewText: String {
        return "This app will not be fully functional after February 10, 2020.\n"
    }
    
    var bannerViewButtonText: String {
        return "View Announcement"
    }
    
    var persistenceMinimizedKey: String {
        return "BannerViewController.minimized"
    }
    
    func update(for minimized: Bool) {
        bannerView.textView.layer.addFadeTransition()
        bannerView.textView.text = minimized ? minimizedBannerViewText : bannerViewText
        UserDefaults.standard.set(minimized, forKey: persistenceMinimizedKey)
        UserDefaults.standard.synchronize()
    }
}

extension CALayer {
    func addFadeTransition() {
        let transition = CATransition()
        transition.type = kCATransitionFade
        transition.duration = 0.25
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        add(transition, forKey: kCATransition)
    }
}
