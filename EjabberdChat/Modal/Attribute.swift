//
//  Attribute.swift
//  EjabberdChat
//
//  Created by Neil Jain on 23/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import UIKit

struct Attributes {
    var font: UIFont
    var maximumWidth: CGFloat
    var maximumHeight: CGFloat
    var textContentInsets: UIEdgeInsets
    
    static private var cache: [String: CGSize] = [:]
}

extension Attributes {
    
    var maxSize: CGSize {
        var size = CGSize(width: maximumWidth, height: maximumWidth)
        size.width -= (textContentInsets.left + textContentInsets.right)
        size.height -= (textContentInsets.top + textContentInsets.bottom)
        return size
    }
    
    func size(for text: String) -> CGSize {
        if let precalculatedSize = Attributes.cache[text] {
            return precalculatedSize
        }
        let atts = [NSAttributedString.Key.font: font]
        let rect = (text as NSString).boundingRect(with: maxSize, options: NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin), attributes: atts, context: nil)
        var size = rect.size
        size.width += (textContentInsets.left + textContentInsets.right)
        size.height += (textContentInsets.top + textContentInsets.bottom)
        Attributes.cache[text] = size
        return size
    }
}
