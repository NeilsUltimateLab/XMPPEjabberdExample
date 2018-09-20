//
//  StreamManager.swift
//  EjabberdChat
//
//  Created by Neil Jain on 15/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import UIKit
import XMPPFramework

class StreamManager: NSObject {
    
    static let shared = StreamManager()
    var host: String = "192.168.43.115"
    var port: UInt16 = 5222
    var stream: XMPPStream!
    var creds: LoginCreds? {
        didSet {
            stop()
            stream.myJID = creds?.jid
            connect()
            self.users.removeAll()
        }
    }
    var connectionTimeOut: TimeInterval = 5
    let rosterStorage = XMPPRosterCoreDataStorage()
    let messageArchiving = XMPPMessageArchivingCoreDataStorage.sharedInstance()
    
    lazy var messageArchivingModule: XMPPMessageArchiving = {
        return XMPPMessageArchiving(messageArchivingStorage: messageArchiving, dispatchQueue: DispatchQueue.main)
    }()
    
    var xmppRoster: XMPPRoster!
    var onLogin: (()->Void)?
    var onMessageRecieve: ((String)->Void)?
    var onPresenceUpdate: ((String)->Void)?
    var onRosterRecieve: (([User]) -> Void)?
    
    private var users: [User] = []
    
    var isRegistered: Bool {
        return UserDefaults.standard.bool(forKey: "isRegistered")
    }
    
    override init() {
        super.init()
        stream = XMPPStream()
        stream.hostName = host
        stream.hostPort = port
        stream.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppRoster = XMPPRoster(rosterStorage: rosterStorage)
        xmppRoster.autoFetchRoster = true
        xmppRoster.addDelegate(self, delegateQueue: DispatchQueue.main)
        messageArchivingModule.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    func connect() {
        guard stream.isDisconnected else { return }
        do {
            try stream.connect(withTimeout: connectionTimeOut)
        } catch {
            print(error)
        }
    }
    
    func start() {
        guard let userName = UserDefaults.standard.string(forKey: "userName"),
            let password = UserDefaults.standard.string(forKey: "password")
        else { return }
        creds = LoginCreds(userName: userName, password: password)
    }
    
    func stop() {
        stream.disconnect()
    }
    
    func rosters() {
        xmppRoster.fetch()
    }
    
    func addRoster(userName: String, nickName: String? = nil) {
        guard let jid = XMPPJID(string: userName) else { return }
        xmppRoster.addUser(jid, withNickname: nickName, groups: nil, subscribeToPresence: true)
    }
    
}

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
        UserDefaults.standard.set(true, forKey: "isRegistered")
        UserDefaults.standard.set(creds?.userName, forKey: "userName")
        UserDefaults.standard.set(creds?.password, forKey: "password")
        onLogin?()
        self.rosters()
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
        print(presence)
        guard let presenceType = presence.nick else { return }
        print(presenceType)
        onPresenceUpdate?(presenceType)
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
}

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
            users.append(user)
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

extension StreamManager: XMPPMessageArchivingStorage {
    func configure(withParent aParent: XMPPMessageArchiving!, queue: DispatchQueue!) -> Bool {
        return true
    }
    
    func archiveMessage(_ message: XMPPMessage!, outgoing isOutgoing: Bool, xmppStream stream: XMPPStream!) {
        print(#function)
        print(message)
    }
}

extension StreamManager {
    struct LoginCreds {
        var userName: String
        var password: String
        
        var jid: XMPPJID? {
            return XMPPJID(string: userName)
        }
    }
}
