//
//  StreamManager+RosterDelegate.swift
//  EjabberdChat
//
//  Created by Neil Jain on 23/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import Foundation
import XMPPFramework

extension StreamManager: XMPPRosterDelegate {
    
    func xmppRosterDidBeginPopulating(_ sender: XMPPRoster, withVersion version: String) {
        print(#function)
    }
    
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster) {
        print(#function)
        self.onRosterRecieve?(self.users)
    }
    
    func xmppRoster(_ sender: XMPPRoster, didReceiveRosterPush iq: XMPPIQ) {
        print(#function)
    }
    
    func xmppRoster(_ sender: XMPPRoster, didReceiveRosterItem item: DDXMLElement) {
        print(#function)
        print(item)
        if let userName = item.attributeStringValue(forName: "jid") {
            let user = User()
            user.userName = userName
            user.status = item.attributeStringValue(forName: "ask")
            self.append(user: user)
            self.fetchVCard(for: user)
        }
    }
    
    func xmppRoster(_ sender: XMPPRoster, didReceivePresenceSubscriptionRequest presence: XMPPPresence) {
        print(#function)
        print(presence)
        if let fromJID = presence.from {
            sender.acceptPresenceSubscriptionRequest(from: fromJID, andAddToRoster: true)
        }
    }
    
}
