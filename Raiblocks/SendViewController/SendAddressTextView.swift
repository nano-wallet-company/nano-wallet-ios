//
//  SendAddressTextView.swift
//  Nano
//
//  Created by Zack Shapiro on 2/2/18.
//  Copyright © 2018 Nano. All rights reserved.
//

import UIKit

// Will refactor this and SeedTextView into a common base class in the future 
final class SendAddressTextView: UITextView {

    init() {
        super.init(frame: .zero, textContainer: nil)

        isEditable = true
        textAlignment = .center
        textColor = Styleguide.Colors.darkBlue.color
        font = Styleguide.Fonts.nunitoRegular.font(ofSize: 16)
        returnKeyType = .done
        isScrollEnabled = false
        tintColor = Styleguide.Colors.lightBlue.color
        autocorrectionType = .no
        spellCheckingType = .no
        autocapitalizationType = .none
        layer.cornerRadius = 3
        clipsToBounds = true
        textContainerInset = UIEdgeInsets(top: 22, left: 56, bottom: 18, right: 56)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func togglePlaceholder(show: Bool) {
        if let label = viewWithTag(50) as? UILabel {
            label.isHidden = !show
        }
    }

}


extension SendAddressTextView: UITextViewDelegate {

    override open var bounds: CGRect {
        didSet {
            self.resizePlaceholder()
        }
    }

    public var placeholder: String? {
        get {
            var placeholderText: String?

            if let label = self.viewWithTag(50) as? UILabel {
                placeholderText = label.text
            }

            return placeholderText
        }

        set {
            if let label = self.viewWithTag(50) as? UILabel {
                label.text = newValue
                label.sizeToFit()
            } else {
                self.addPlaceholder(newValue!)
            }
        }
    }

    private func resizePlaceholder() {
        if let label = self.viewWithTag(50) as? UILabel {
            let x = self.textContainer.lineFragmentPadding
            let y = self.textContainerInset.top - 2
            let width = self.frame.width - (x * 2)
            let height = label.frame.height
            label.textAlignment = .center

            label.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }

    private func addPlaceholder(_ placeholderText: String) {
        let placeholderLabel = UILabel()

        placeholderLabel.text = placeholderText
        placeholderLabel.sizeToFit()

        placeholderLabel.font = self.font
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.tag = 50

        placeholderLabel.isHidden = self.text.count > 0

        self.addSubview(placeholderLabel)
        self.resizePlaceholder()
    }
}
