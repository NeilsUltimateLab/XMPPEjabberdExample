//
//  ChatCell.swift
//  EjabberdChat
//
//  Created by Neil Jain on 16/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import UIKit

class ChatCell: UICollectionViewCell {

    @IBOutlet weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.layer.cornerRadius = 8
        self.contentView.clipsToBounds = true
    }
    
    func configure(with text: String) {
        self.textLabel.text = text
    }

}
