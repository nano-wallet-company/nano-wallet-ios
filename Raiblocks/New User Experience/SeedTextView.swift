//
//  SeedTextView.swift
//  Nano
//
//  Created by Zack Shapiro on 1/28/18.
//  Copyright © 2018 Nano Wallet Company. All rights reserved.
//

import UIKit


final class SeedTextView: UITextView {

    init() {
        super.init(frame: .zero, textContainer: nil)

        isEditable = true
        layer.cornerRadius = 3
        font = UIFont.systemFont(ofSize: 14, weight: .regular)
        clipsToBounds = true
        backgroundColor = Styleguide.Colors.darkBlue.color
        textAlignment = .center
        textColor = .white
        returnKeyType = .done
        isScrollEnabled = false
        autocorrectionType = .no
        spellCheckingType = .no
        tintColor = Styleguide.Colors.lightBlue.color
        autocapitalizationType = .allCharacters
        textContainerInset = UIEdgeInsets(top: 15, left: 50, bottom: 12, right: 50)
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

extension SeedTextView: UITextViewDelegate {

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
