//
//  User.swift
//  EjabberdChat
//
//  Created by Neil Jain on 23/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import Foundation
import XMPPFramework

class User {
    var userName: String = ""
    var status: String?
    var presence: String?
    var nick: String? = nil
    var imageData: Data? = nil
}

extension User {
    var jid: XMPPJID? {
        return XMPPJID(string: userName)
    }
}
