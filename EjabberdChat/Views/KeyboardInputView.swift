//
//  KeyboardInputView.swift
//  EjabberdChat
//
//  Created by Neil Jain on 23/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import UIKit

class KeyboardInputView: UIView {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    
    var onTextCharacterChange: (()->Void)?
    
    private let maxHeight: CGFloat = 100
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }
    
    private func configure() {
        self.textView.layer.cornerRadius = 14
        self.textView.layer.masksToBounds = true
        self.textView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).cgColor
        self.textView.layer.borderWidth = 1
        self.textView.textContainerInset.left = 8
        self.textView.textContainerInset.right = 8
        self.textView.textContainerInset.top = 4
        self.textView.textContainerInset.bottom = 4
        self.textView.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        self.textView.delegate = self
        self.textView.isScrollEnabled = false
    }
    
    override var intrinsicContentSize: CGSize {
        let maxSize = CGSize(width: textView.frame.width, height: CGFloat.infinity)
        let textSize = self.textView.sizeThatFits(maxSize)
        self.heightConstraint.constant = textSize.height
        
        let size = CGSize(width: self.frame.width, height: textSize.height + 16)
        return size
    }
    
    var text: String? {
        return textView.text
    }
    
    func reset() {
        self.textView.text = nil
    }
}

extension KeyboardInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.invalidateIntrinsicContentSize()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        onTextCharacterChange?()
        return true
    }
}
