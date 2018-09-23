//
//  StreamManager.swift
//  EjabberdChat
//
//  Created by Neil Jain on 15/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import UIKit
import XMPPFramework

typealias ArchivedMessage = XMPPMessageArchiving_Message_CoreDataObject

class StreamManager: NSObject {
    
    static let shared = StreamManager()
    var host: String = "172.20.10.4"
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
    let vCardStorage = XMPPvCardCoreDataStorage.init(inMemoryStore: ())
    
    lazy var vCardModule: XMPPvCardTempModule = {
        let module = XMPPvCardTempModule(vCardStorage: vCardStorage!)
        module.addDelegate(self, delegateQueue: DispatchQueue.main)
        return module
    }()
    
    lazy var messageArchivingModule: XMPPMessageArchiving = {
        return XMPPMessageArchiving(messageArchivingStorage: messageArchiving, dispatchQueue: DispatchQueue.main)
    }()
    
    var xmppRoster: XMPPRoster!
    var onLogin: (()->Void)?
    var onMessageRecieve: ((String)->Void)?
    var onPresenceUpdate: ((String)->Void)?
    var onRosterRecieve: (([User]) -> Void)?
    var onvCardRecieve: ((User)->Void)?
    
    fileprivate(set) var users: [User] = []
    
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
    
    func update(presence: Presence) {
        switch presence {
        case .available:
            let xPresence = XMPPPresence(type: "available")
            xPresence.addNick("Online")
            stream.send(xPresence)
            break
        case .unavailable:
            let xPresence = XMPPPresence(type: "unavailable")
            stream.send(xPresence)
            break
        case .typing(to: let user):
            let xPresence = XMPPPresence(type: "available", to: user.jid)
            xPresence.addNick("typing...")
            stream.send(xPresence)
        case .availableTo(to: let user):
            let xPresence = XMPPPresence(type: "available", to: user.jid)
            xPresence.addNick("Online")
            stream.send(xPresence)
        }
    }
    
    func send(_ item: Chat) {
        switch item {
        case .chat(body: let message, to: let user):
            let xMessage = XMPPMessage(type: "chat", to: user.jid)
            xMessage.addBody(message)
            stream.send(xMessage)
        }
    }
    
    func fetchVCard(for user: User) {
        guard let jid = user.jid else { return }
        vCardModule.fetchvCardTemp(for: jid)
    }
    
    func fetchVCard(for jid: XMPPJID) {
        vCardModule.fetchvCardTemp(for: jid)
    }
    
    func updateMyVCard(with data: User) {
        guard let xVCarTemp = vCardModule.myvCardTemp else { return }
        xVCarTemp.logo = data.imageData
        xVCarTemp.nickname = data.nick
        vCardModule.updateMyvCardTemp(xVCarTemp)
    }
    
    func append(user: User) {
        self.users.append(user)
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

extension StreamManager {
    enum Presence {
        case available
        case unavailable
        case typing(to: User)
        case availableTo(to: User)
    }
}

extension StreamManager {
    enum Chat {
        case chat(body: String, to: User)
    }
}
