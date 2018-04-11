//
//  BackgroundViewController.swift
//  Nano
//
//  Created by Zack Shapiro on 1/25/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

import UIKit

import Cartography


class BackgroundViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Styleguide.Colors.darkBlue.color

        let imageView = UIImageView(image: UIImage(named: "largeNanoMarkBlue"))
        view.addSubview(imageView)
        constrain(imageView) {
            $0.center == $0.superview!.center
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
