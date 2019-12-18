//
//  BannerView.swift
//  Raiblocks
//
//  Created by Fawaz Tahir on 1/6/19.
//  Copyright © 2019 Zack Shapiro. All rights reserved.
//

import Foundation
import Cartography

class BannerView: UIView {
    
    var linkTapActionHandler: (()->())? = nil
    var minimizeActionHandler: ((Bool)->())? = nil
    var actionHandler: (()->())? = nil
    
    let textView = UITextView(frame: .zero)
    let actionButton = NanoButton(withType: .darkBlue)
    
    private let minimizeButton = UIButton(type: .custom)
    
    var minimized: Bool = false {
        didSet {
            update(for: minimized)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BannerView {
    
    func setup() {
        setupConstraints()
        setup(textView: textView)
        setup(minimizeButton: minimizeButton)
        setup(actionButton: actionButton)
        textView.delegate = self
        
        backgroundColor = Styleguide.Colors.lime.color
        update(for: minimized)
        setupGestures()
    }
    
    func setupConstraints() {
        addSubview(textView)
        addSubview(minimizeButton)
        addSubview(actionButton)
        
        constrain(textView, minimizeButton) {
            $0.left == $0.superview!.left
            $0.right == $1.left
            $0.height == $0.superview!.height
        }
        
        constrain(actionButton) {
            $0.left == $0.superview!.left + textView.textContainerInset.left + 15
            $0.right == $0.superview!.right + textView.textContainerInset.right - 15
            $0.bottom == $0.superview!.bottom + textView.textContainerInset.left - 15
            //            $0.width == CGFloat(100)
            //            $0.height == CGFloat(33)
        }
        
        constrain(minimizeButton) {
            $0.right == $0.superview!.right - 5
            $0.top == $0.superview!.top + 5
            $0.width == CGFloat(35)
            $0.height == CGFloat(35)
        }
    }
    
    func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(minimizeButtonTapped))
        addGestureRecognizer(tapGesture)
    }
    
    func setup(minimizeButton: UIButton) {
        minimizeButton.imageView?.contentMode = .scaleAspectFit
        minimizeButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        minimizeButton.addTarget(self, action: #selector(minimizeButtonTapped), for: .touchUpInside)
    }
    
    func setup(actionButton: NanoButton) {
        actionButton.titleLabel?.textAlignment = .center
        actionButton.titleLabel?.numberOfLines = 1
        actionButton.titleLabel?.lineBreakMode = .byTruncatingTail
        actionButton.titleLabel?.font = Styleguide.Fonts.notoSansRegular.font(ofSize: 15)
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.center = textView.center
    }
    
    func setup(textView: UITextView) {
        textView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12)
        textView.dataDetectorTypes = [.link]
        textView.textAlignment = .left
        textView.isEditable = false
        textView.isUserInteractionEnabled = false
        textView.font = Styleguide.Fonts.nunitoRegular.font(ofSize: 14)
        textView.textColor = Styleguide.Colors.darkBlue.color
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
    }
}

private extension BannerView {
    func update(for minimized: Bool) {
        let image = minimized ? UIImage(named: "maximizeIcon") : UIImage(named: "minimizeIcon")
        minimizeButton.layer.addFadeTransition()
        minimizeButton.setImage(image, for: .normal)
    }
    
    @objc func minimizeButtonTapped() {
        minimized = minimized == false
        minimizeActionHandler?(minimized)
    }
    
    @objc func actionButtonTapped() {
        actionHandler?()
    }
}

extension BannerView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        linkTapActionHandler?()
        return false
    }
    
    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return false
    }
}
