//
//  StreamManager+vCardDelegate.swift
//  EjabberdChat
//
//  Created by Neil Jain on 23/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import Foundation
import XMPPFramework

extension StreamManager: XMPPvCardTempModuleDelegate {
    func xmppvCardTempModule(_ vCardTempModule: XMPPvCardTempModule, didReceivevCardTemp vCardTemp: XMPPvCardTemp, for jid: XMPPJID) {
        print(#function)
        print(vCardTemp)
        guard let user = self.users.filter ({ (user) -> Bool in
            user.jid == jid
        }).first else { return }
        user.nick = vCardTemp.nickname
        user.imageData = vCardTemp.logo
        self.onvCardRecieve?(user)
    }
    
    func xmppvCardTempModule(_ vCardTempModule: XMPPvCardTempModule, failedToFetchvCardFor jid: XMPPJID, error: DDXMLElement?) {
        print(#function)
        if let err = error {
            print(err)
        }
    }
    
    func xmppvCardTempModule(_ vCardTempModule: XMPPvCardTempModule, failedToUpdateMyvCard error: DDXMLElement?) {
        print(#function)
        if let err = error {
            print(err)
        }
    }
    
    func xmppvCardTempModuleDidUpdateMyvCard(_ vCardTempModule: XMPPvCardTempModule) {
        print(#function)
        print(vCardTempModule)
    }
}
