//
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import UIKit

import Cartography
import ReactiveSwift


public enum DecodingHandlerError : Error {
    case unableToDecode
}

class HomeViewController: UIViewController {

    private let viewModel: HomeViewModel
    private var address: Address {
        return viewModel.address
    }

    private let (lifetime, token) = Lifetime.make()

    // MARK: - UI Elements

    private weak var pricePageViewController: PricePageViewController?
    private weak var pageControl: UIPageControl?
    private weak var refreshControl: UIRefreshControl?
    private weak var tableView: UITableView?
    private weak var sendButton: NanoButton?

    // MARK: -

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        AnalyticsEvent.homeViewed.track()

        // Updates price when you scroll through the Page View Controller
        viewModel.lastBTCTradePrice
            .producer
            .take(during: lifetime)
            .observe(on: UIScheduler())
            .startWithValues { _ in
                self.tableView?.refreshControl?.endRefreshing()
            }

        viewModel.transactions
            .producer
            .take(during: lifetime)
            .observe(on: UIScheduler())
            .startWithValues { _ in
                self.tableView?.reloadData()
            }

        SignalProducer.combineLatest(viewModel.hasNetworkConnection, viewModel.addressIsOnNetwork, viewModel.isCurrentlySyncing, viewModel.transactableAccountBalance)
            .producer
            .take(during: lifetime)
            .observe(on: UIScheduler())
            .startWithValues { hasNetworkConnection, addressIsOnNetwork, isCurrentlySyncing, transactableBalance in
                guard hasNetworkConnection else { self.sendButton?.isEnabled = false; return }
                guard addressIsOnNetwork   else { self.sendButton?.isEnabled = false; return }
                guard transactableBalance.compare(0) == .orderedDescending else { self.sendButton?.isEnabled = false; return }

                self.sendButton?.isEnabled = !isCurrentlySyncing
        }

        viewModel.lastBlockCount
            .producer
            .take(during: lifetime)
            .observe(on: UIScheduler())
            .startWithValues { _ in
                if let _ = self.tableView?.refreshControl?.isRefreshing {
                    self.tableView?.refreshControl?.endRefreshing()
                }
            }

        viewModel.localCurrency
            .producer
            .take(during: lifetime)
            .observe(on: UIScheduler())
            .startWithValues { _ in
                self.viewModel.fetchLatestPrices()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = Styleguide.Colors.darkBlue.color
        navigationController?.navigationBar.tintColor = Styleguide.Colors.lightBlue.color
        super.viewWillAppear(animated)

        viewModel.isCurrentlySending.value = false
        if viewModel.socket.readyState != .open {
            viewModel.socket.open()
        }
    }

    override func viewDidLoad() {
        defer { viewModel.fetchLatestPrices() }

        super.viewDidLoad()

        view.backgroundColor = Styleguide.Colors.darkBlue.color

        self.navigationItem.titleView = UIImageView(image: UIImage(named: "nanologo"))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "settings"), style: .done, target: self, action: #selector(showSettings))
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = Styleguide.Colors.darkBlue.color
        navigationController?.navigationBar.tintColor = Styleguide.Colors.lightBlue.color
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.shadowImage = UIImage() // hides the bottom border
        self.navigationItem.hidesBackButton = true

        // Hides 'Back' text from Back button on Send VC or any VC we push to
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(UIWebView.goBack))

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshWithButton))

        let topSection = UIView()
        topSection.backgroundColor = Styleguide.Colors.darkBlue.color
        view.addSubview(topSection)
        constrain(topSection) {
            $0.top == $0.superview!.top
            $0.height == CGFloat(88)
            $0.width == $0.superview!.width
        }

        let pageViewController = PricePageViewController(viewModel: viewModel)
        pageViewController.pricePageDelegate = self
        pageViewController.view.backgroundColor = Styleguide.Colors.darkBlue.color
        addChildViewController(pageViewController)
        topSection.addSubview(pageViewController.view)
        pageViewController.didMove(toParentViewController: self)
        constrain(pageViewController.view) {
            $0.top == $0.superview!.top
            $0.width == $0.superview!.width
            $0.height == CGFloat(66)
        }
        self.pricePageViewController = pageViewController

        let pageControl = UIPageControl()
        pageControl.backgroundColor = .clear
        pageControl.pageIndicatorTintColor = Styleguide.Colors.lightBlue.color.withAlphaComponent(0.25)
        pageControl.currentPageIndicatorTintColor = Styleguide.Colors.lightBlue.color
        pageControl.numberOfPages = pageViewController.vcs.count
        pageControl.addTarget(self, action: #selector(didChangePageControlValue(_:)), for: .touchUpInside)
        topSection.addSubview(pageControl)
        constrain(pageControl, pageViewController.view) {
            $0.centerX == $1.centerX
            $0.top == $1.bottom - CGFloat(12)
        }
        self.pageControl = pageControl

        let border = UIView()
        border.backgroundColor = Styleguide.Colors.darkBlue.color.darkerColor(percent: 0.2)
        topSection.addSubview(border)
        constrain(border) {
            $0.height == CGFloat(1)
            $0.width == $0.superview!.width
            $0.bottom == $0.superview!.bottom
        }

        let receiveButton = setupButton(withTransactionType: .receive)
        receiveButton.addTarget(self, action: #selector(receiveNano), for: .touchUpInside)
        view.addSubview(receiveButton)
        constrain(receiveButton) {
            $0.bottom == $0.superview!.bottom - CGFloat(34)
            $0.right == $0.superview!.centerX - CGFloat(10)
            $0.width == $0.superview!.width * CGFloat(0.43)
            $0.height == CGFloat(55)
        }

        let sendButton = setupButton(withTransactionType: .send)
        sendButton.addTarget(self, action: #selector(sendNano), for: .touchUpInside)
        view.addSubview(sendButton)
        constrain(sendButton, receiveButton) {
            $0.bottom == $1.bottom
            $0.left == $0.superview!.centerX + CGFloat(10)
            $0.width == $1.width
            $0.height == $1.height
        }
        self.sendButton = sendButton

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl

        let tableView = UITableView()
        tableView.refreshControl = refreshControl
        tableView.backgroundColor = .white
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: "TransactionCell")
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        constrain(tableView, sendButton, topSection) {
            $0.top == $2.bottom
            $0.width == $0.superview!.width
            $0.bottom == $1.top - CGFloat(33)
        }
        self.tableView = tableView

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if !appDelegate.devConfig.skipLegal {
            if !viewModel.hasCompletedLegalAgreements {
                let vc = LegalViewController(useForLoggedInState: true)

                if !viewModel.hasCompletedAnalyticsOptIn {
                    vc.delegate = self
                }

                present(vc, animated: true)
            }

            if !viewModel.hasCompletedAnalyticsOptIn {
                showAnalyticsAlert()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func setupButton(withTransactionType type: TransactionType) -> NanoButton {
        let button = NanoButton(withType: .lightBlueSend)
        button.setAttributedTitle(type.description.uppercased())

        return button
    }

    private func genericDecoder<T: Decodable>(decodable: T.Type, from data: Data) -> T? {
        return try? JSONDecoder().decode(decodable, from: data)
    }

    @objc func sendNano() {
        viewModel.isCurrentlySending.value = true

        let vc = SendViewController(viewModel: SendViewModel(homeSocket: self.viewModel.socket))
        vc.delegate = self

        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc func receiveNano() {
        let vc = ReceiveViewController(viewModel: ReceiveViewModel(address: address))
        let nc = UINavigationController(rootViewController: vc)

        present(nc, animated: true, completion: nil)
    }

    private func showAlertWhenOffline(endRefreshing: Bool = false) {
        let ac = UIAlertController(title: "You are offline".localized(), message: "Nano Wallet is having trouble connecting to the network right now.\n\nPlease try again.".localized(), preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "View Account on Nanode".localized(), style: .default) { _ in
            guard let url = URL(string: "https://www.nanode.co/account/" + self.address.longAddress) else { return }

            self.present(WebViewController(url: url, useForLegalPurposes: false), animated: true, completion: nil)

        })
        ac.addAction(UIAlertAction(title: "Dismiss".localized(), style: .cancel) { _ in
            if endRefreshing {
                self.refreshControl?.endRefreshing()
            }
        })

        present(ac, animated: true)
    }

    @objc func refreshWithButton() {
        guard viewModel.hasNetworkConnection.value else { return showAlertWhenOffline() }
        guard let sendButton = sendButton, !viewModel.isCurrentlySending.value else { return }

        // Just in case the send button is disabled
        if viewModel.transactableAccountBalance.value.compare(NSDecimalNumber(value: 0)) == .orderedDescending && !sendButton.isEnabled {
            sendButton.isEnabled = true
        }

        viewModel.refresh()
    }

    @objc func refresh(_ sender: UIRefreshControl) {
        guard viewModel.hasNetworkConnection.value else { return showAlertWhenOffline(endRefreshing: true) }
        guard let sendButton = sendButton, !viewModel.isCurrentlySyncing.value else { return sender.endRefreshing() }

        // Just in case the send button is disabled
        if viewModel.transactableAccountBalance.value.compare(NSDecimalNumber(value: 0)) == .orderedDescending && !sendButton.isEnabled {
            sendButton.isEnabled = true
        }

        viewModel.refresh()
    }

    @objc func showSettings() {
        let vc = SettingsViewController(localCurrency: viewModel.localCurrency.value)
        vc.delegate = self
        let nc = UINavigationController(rootViewController: vc)

        present(nc, animated: true, completion: nil)
    }

    @objc func didChangePageControlValue(_ sender: UIPageControl) {
        pricePageViewController?.scrollToViewController(index: sender.currentPage)
    }

}


extension HomeViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath) as! TransactionTableViewCell
        cell.viewModel = TransactionViewModel(item: viewModel.transactions.value[indexPath.row])
        cell.delegate = self 

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func numberOfSections(in tableView: UITableView) -> Int {
         return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.transactions.value.count
    }

}


extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        showExplorerAlert(forIndexPath: indexPath)
    }

    private func showExplorerAlert(forIndexPath indexPath: IndexPath) {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Send Nano to Address".localized(), style: .default) { _ in
            let vc = SendViewController(viewModel: SendViewModel(homeSocket: self.viewModel.socket, toAddress: self.viewModel.transactions.value[indexPath.row].fromAddress))
            vc.delegate = self

            self.navigationController?.pushViewController(vc, animated: true)
        })

        ac.addAction(UIAlertAction(title: "View Transaction on Explorer".localized(), style: .default) { _ in self.view(atIndexPath: indexPath) })

        ac.addAction(UIAlertAction(title: "Copy Address".localized(), style: .default) { _ in
            if let address = self.viewModel.transactions.value[indexPath.row].fromAddress {
                self.cellWasLongPressed(address: address)
            }
        })

        ac.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))

        present(ac, animated: true, completion: nil)
    }

    private func view(atIndexPath indexPath: IndexPath) {
        guard
            let hash = self.viewModel.transactions.value[indexPath.row].hash,
            let url = URL(string: "https://www.nanode.co/block/" + hash)
        else { return }

        self.present(WebViewController(url: url, useForLegalPurposes: false), animated: true, completion: nil)
    }

    // TODO: clean this up
    private func showAnalyticsAlert() {
        self.viewModel.startAnalyticsService()
    }

}


extension HomeViewController: PricePageViewControllerDelegate {

    func pricePageViewController(_ pricePageViewController: PricePageViewController, didUpdatePageCount count: Int) {
        pageControl?.numberOfPages = count
    }

    func pricePageViewController(_ pricePageViewController: PricePageViewController, didUpdatePageIndex index: Int) {
        pageControl?.currentPage = index
    }

}


extension HomeViewController: SettingsViewControllerDelegate {

    func localCurrencyWasSelected(currency: Currency) {
        viewModel.update(localCurrency: currency)

        viewModel.refresh()
    }

}


extension HomeViewController: SendViewControllerDelegate {

    func didFinishWithViewController() {
        viewModel.isCurrentlySending.value = false
        viewModel.refresh(andFetchLatestFrontier: true)

        self.tableView?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)

        self.navigationController?.popViewController(animated: true)
    }

}


extension HomeViewController: TransactionTableViewCellDelegate {

    func cellWasLongPressed(address: Address) {
        UIPasteboard.general.string = address.longAddress

        
        let ac = UIAlertController(title: "Address Copied".localized(), message: String.localizedStringWithFormat("%@ was copied.".localized(), address.longAddress), preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Okay".localized(), style: .default))

        present(ac, animated: true)
    }

}


extension HomeViewController: LegalViewControllerDelegate {

    func didFinishWithLegalVC() {
        showAnalyticsAlert()
    }

}
