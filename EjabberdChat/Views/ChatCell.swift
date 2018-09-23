//
//  ChatCell.swift
//  EjabberdChat
//
//  Created by Neil Jain on 16/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import UIKit
import XMPPFramework

class ChatCell: UICollectionViewCell {

    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet var bubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var bubbleTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var bubbleWidthConstraint: NSLayoutConstraint!
    
    var isOutgoing: Bool = true {
        didSet {
            self.bubbleLeadingConstraint.isActive = !isOutgoing
            self.bubbleTrailingConstraint.isActive = isOutgoing
            self.bubbleView.backgroundColor = !isOutgoing ? #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) : #colorLiteral(red: 0, green: 0.5157565983, blue: 1, alpha: 1)
            self.textLabel.textColor = isOutgoing ? .white : UIColor.darkText
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.bubbleView.layer.cornerRadius = 16
        self.bubbleView.layer.masksToBounds = true
    }
    
    func configure(with text: String) {
        self.textLabel.text = text
    }
    
    func configure(with message: XMPPMessage, width: CGFloat, isOutgoing: Bool) {
        self.textLabel.text = message.body
        bubbleWidthConstraint.constant = width
        self.isOutgoing = isOutgoing
    }

}
