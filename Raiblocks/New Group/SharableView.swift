//
//  SharableView.swift
//  Raiblocks
//
//  Created by Zack Shapiro on 12/29/17.
//  Copyright © 2017 Zack Shapiro. All rights reserved.
//

import UIKit

import Cartography
import EFQRCode

class SharableView: UIView {

    init(address: Address) {
        super.init(frame: .zero)

        layer.cornerRadius = 8
        clipsToBounds = true
        backgroundColor = Styleguide.Colors.darkBlue.color

        let imgHolder = UIView()
        imgHolder.layer.cornerRadius = 3
        imgHolder.clipsToBounds = true
        imgHolder.backgroundColor = .white
        addSubview(imgHolder)
        constrain(imgHolder) {
            $0.left == $0.superview!.left + CGFloat(20)
            $0.width == CGFloat(140)
            $0.height == CGFloat(140)
            $0.centerY == $0.superview!.centerY
        }

        let qrCode = EFQRCode.generate(
            content: address.longAddress,
            backgroundColor: UIColor.white.coreImageColor,
            foregroundColor: Styleguide.Colors.darkBlue.color.coreImageColor,
            watermark: UIImage(named: "largeNanoMarkBlue")?.cgImage,
            watermarkMode: .scaleAspectFit
        )!

        let imageView = UIImageView(image: UIImage(cgImage: qrCode))
        imgHolder.addSubview(imageView)
        constrain(imageView) {
            $0.center == $0.superview!.center
            $0.width == CGFloat(100)
            $0.height == CGFloat(100)
        }

        let rightView = UIView()
        addSubview(rightView)
        constrain(rightView, imgHolder) {
            $0.left == $1.right + CGFloat(40)
            $0.right == $0.superview!.right - CGFloat(20)
            $0.top == $1.top
            $0.bottom == $1.bottom
        }

        let logo = UIImageView(image: UIImage(named: "nanologo"))
        rightView.addSubview(logo)
        constrain(logo) {
            $0.top == $0.superview!.top
            $0.left == $0.superview!.left
        }

        let nanoLabel = UILabel()
        nanoLabel.textColor = .white
        nanoLabel.font = Styleguide.Fonts.nunitoLight.font(ofSize: 30)
        let text = NSMutableAttributedString(string: "NANO")
        text.addAttribute(.kern, value: 5.0, range: NSMakeRange(0, text.length))
        nanoLabel.attributedText = text

        rightView.addSubview(nanoLabel)
        constrain(nanoLabel, logo) {
            $0.left == $1.right + CGFloat(12)
            $0.top == $1.top - 8
        }

        let addressLabel = UILabel()
        let addressText =  NSMutableAttributedString(attributedString: address.longAddressWithColorOnDarkBG)
        addressLabel.numberOfLines = 0
        addressLabel.lineBreakMode = .byCharWrapping
        addressLabel.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        addressText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, addressText.length))
        addressLabel.attributedText = addressText
        rightView.addSubview(addressLabel)
        constrain(addressLabel, imgHolder) {
            $0.left == $0.superview!.left
            $0.centerY == $1.centerY + CGFloat(4)
            $0.right == $0.superview!.right
        }

        let cashtag = UILabel()
        cashtag.text = "$nano"
        cashtag.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 16)
        cashtag.textColor = Styleguide.Colors.lightBlue.color
        rightView.addSubview(cashtag)
        constrain(cashtag) {
            $0.left == $0.superview!.left
            $0.bottom == $0.superview!.bottom
        }

        let website = UILabel()
        website.text = "nano.co"
        website.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 16)
        website.textColor = Styleguide.Colors.lightBlue.color
        rightView.addSubview(website)
        constrain(website, cashtag) {
            $0.centerY == $1.centerY
            $0.left == $1.right + CGFloat(20)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }

}
