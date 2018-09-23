//
//  StreamManager+StreamDelegate.swift
//  EjabberdChat
//
//  Created by Neil Jain on 23/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import Foundation
import XMPPFramework

extension StreamManager: XMPPStreamDelegate {
    func xmppStreamWillConnect(_ sender: XMPPStream) {
        print("Will connect")
    }
    
    func xmppStreamDidConnect(_ sender: XMPPStream) {
        print("Did connect")
        guard let password = creds?.password else { return }
        do {
            try sender.authenticate(withPassword: password)
        } catch {
            print(error)
        }
    }
    
    func xmppStreamConnectDidTimeout(_ sender: XMPPStream) {
        print("Timed out")
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        print("Auth done")
        sender.send(XMPPPresence())
        xmppRoster.activate(stream)
        messageArchivingModule.clientSideMessageArchivingOnly = false
        messageArchivingModule.activate(stream)
        vCardModule.activate(stream)
        UserDefaults.standard.set(true, forKey: "isRegistered")
        UserDefaults.standard.set(creds?.userName, forKey: "userName")
        UserDefaults.standard.set(creds?.password, forKey: "password")
        onLogin?()
        self.rosters()
        self.update(presence: .available)
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        guard let messageBody = message.body else { return }
        onMessageRecieve?(messageBody)
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive iq: XMPPIQ) -> Bool {
        print(iq)
        guard let element = iq.element(forName: "query", xmlnsPrefix: "jabber:iq:roster") else { return false }
        let items = element.elements(forName: "item")
        for item in items {
            print(item)
        }
        return false
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive presence: XMPPPresence) {
        onPresenceUpdate?( presence.nick ?? "")
    }
    
    func xmppStream(_ sender: XMPPStream, didReceiveError error: DDXMLElement) {
        print(#function)
        print(error)
    }
    
    func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        print(#function)
        print(message)
    }
    
    func xmppStream(_ sender: XMPPStream, didSend presence: XMPPPresence) {
        print(#function)
        print(presence)
    }
    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        print(#function)
        print(error)
    }
}
