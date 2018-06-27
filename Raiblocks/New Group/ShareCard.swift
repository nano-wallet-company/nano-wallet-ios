//
//  ShareCard.swift
//  Nano
//
//  Created by Zack Shapiro on 12/29/17.
//  Copyright © 2017 Nano Wallet Company. All rights reserved.
//

import UIKit

import Cartography
import EFQRCode


class ShareCard: UIView {

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
            $0.left == $0.superview!.left + (isiPhoneSE() ? CGFloat(10) : CGFloat(20))
            let width = $0.superview!.height * CGFloat(0.8)
            $0.width == width
            $0.height == width
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
            let width = $0.superview!.width * CGFloat(0.8)
            $0.width == width
            $0.height == width
        }

        let rightView = UIView()
        addSubview(rightView)
        constrain(rightView, imgHolder) {
            if isiPhoneSE() {
                $0.width == $0.superview!.width * CGFloat(0.50)
            } else {
                $0.width == $0.superview!.width * CGFloat(0.45)
            }
            $0.right == $0.superview!.right - (isiPhoneSE() ? CGFloat(10) : CGFloat(20))
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
        nanoLabel.font = Styleguide.Fonts.nunitoLight.font(ofSize: 27)
        let text = NSMutableAttributedString(string: "NANO")
        text.addAttribute(.kern, value: 4.0, range: NSMakeRange(0, text.length))
        nanoLabel.attributedText = text

        rightView.addSubview(nanoLabel)
        constrain(nanoLabel, logo) {
            $0.left == $1.right + CGFloat(12)
            $0.top == $1.top - 6
        }

        let addressLabel = UILabel()
        let addressText =  NSMutableAttributedString(attributedString: address.longAddressWithColorOnDarkBG)
        addressLabel.numberOfLines = 0
        addressLabel.lineBreakMode = .byCharWrapping
        if isiPhoneSE() {
            addressLabel.font = Styleguide.Fonts.notoSansRegular.font(ofSize: 14)
        } else {
            addressLabel.font = Styleguide.Fonts.notoSansRegular.font(ofSize: 16)
        }
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
        if isiPhoneSE() {
            cashtag.font = Styleguide.Fonts.notoSansRegular.font(ofSize: 14)
        } else {
            cashtag.font = Styleguide.Fonts.notoSansRegular.font(ofSize: 16)
        }
        cashtag.textColor = Styleguide.Colors.lightBlue.color
        rightView.addSubview(cashtag)
        constrain(cashtag) {
            $0.left == $0.superview!.left
            $0.bottom == $0.superview!.bottom
        }

        let website = UILabel()
        website.text = "nano.org"
        if isiPhoneSE() {
            website.font = Styleguide.Fonts.notoSansRegular.font(ofSize: 14)
        } else {
            website.font = Styleguide.Fonts.notoSansRegular.font(ofSize: 16)
        }
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
