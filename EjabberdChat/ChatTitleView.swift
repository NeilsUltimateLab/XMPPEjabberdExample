//
//  ChatTitleView.swift
//  EjabberdChat
//
//  Created by Neil Jain on 23/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import UIKit

class ChatTitleView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
    }
    
    func configure(with userName: String) {
        self.nameLabel.text = userName
        self.statusLabel.isHidden = true
        self.imageView.isHidden = true
    }
    
    func updateState(with state: String) {
        UIView.animate(withDuration: 0.5) {
            if state.isEmpty {
                self.statusLabel.isHidden = true
                self.statusLabel.alpha = 0
            } else {
                self.statusLabel.text = state
                self.statusLabel.isHidden = false
                self.statusLabel.alpha = 1
            }
            self.layoutIfNeeded()
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
