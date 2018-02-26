//
//  PricePageViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 12/14/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import UIKit

import Cartography
import ReactiveSwift


protocol PricePageViewControllerDelegate: class {

    func pricePageViewController(_ pricePageViewController: PricePageViewController, didUpdatePageCount count: Int)
    func pricePageViewController(_ pricePageViewController: PricePageViewController, didUpdatePageIndex index: Int)

}


class PricePageViewController: UIPageViewController {

    weak var pricePageDelegate: PricePageViewControllerDelegate?

    private let viewModel: HomeViewModel

    private (set) var vcs: [PriceViewController] = []

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

        vcs = [
            PriceViewController(type: .nano, viewModel: viewModel),
            PriceViewController(type: .btc, viewModel: viewModel),
            PriceViewController(type: .localCurrency, viewModel: viewModel)
        ]

        guard let vc = vcs.first else { fatalError("Could not set price view controller") }

        setViewControllers([vc], direction: .forward, animated: true, completion: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        dataSource = self

        pricePageDelegate?.pricePageViewController(self, didUpdatePageCount: vcs.count)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func scrollToNextViewController() {
        guard let visibleViewController = viewControllers?.first as? PriceViewController else { return }

        if let nextViewController = pageViewController(self, viewControllerAfter: visibleViewController) {
            scrollToViewController(viewController: nextViewController)
        }
    }

    func scrollToViewController(index newIndex: Int) {
        guard let firstViewController = viewControllers?.first as? PriceViewController else { return }

        if let currentIndex = vcs.index(of: firstViewController) {
            let direction: UIPageViewControllerNavigationDirection = newIndex >= currentIndex ? .forward : .reverse
            let nextViewController = vcs[newIndex]

            scrollToViewController(viewController: nextViewController, direction: direction)
        }
    }

    private func scrollToViewController(viewController: UIViewController, direction: UIPageViewControllerNavigationDirection = .forward) {
        setViewControllers([viewController], direction: direction, animated: true, completion: { _ in
            // Setting the view controller programmatically does not fire
            // any delegate methods, so we have to manually notify the
            // delegate of the new index.
            self.notifyDelegateOfNewIndex()
        })
    }

    private func notifyDelegateOfNewIndex() {
        guard let firstViewController = viewControllers?.first as? PriceViewController else { return }

        DispatchQueue.global(qos: .background).async {
            self.viewModel.fetchLatestPrices()

            DispatchQueue.main.async {
                if let index = self.vcs.index(of: firstViewController) {
                    self.pricePageDelegate?.pricePageViewController(self, didUpdatePageIndex: index)
                }
            }
        }
    }

}


extension PricePageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard
            let viewController = viewController as? PriceViewController,
            let viewControllerIndex = vcs.index(of: viewController)
            else { return nil }

        let previousIndex = viewControllerIndex - 1

        guard previousIndex >= 0 else { return nil }

        return vcs[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard
            let viewController = viewController as? PriceViewController,
            let viewControllerIndex = vcs.index(of: viewController)
            else { return nil }

        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = vcs.count

        guard orderedViewControllersCount != nextIndex else { return nil }

        return vcs[nextIndex]
    }

}


extension PricePageViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        notifyDelegateOfNewIndex()
    }

}
