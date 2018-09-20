//
//  ViewController.swift
//  EjabberdChat
//
//  Created by Neil Jain on 15/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import UIKit
import XMPPFramework


class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityLabel: UILabel!
    var reciept: User?
    
    var dataSource: [String] = []
    var sizeCache: [IndexPath: CGSize] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.delegate = self
        self.activityLabel.text = nil
        setupCollectionView()
        keyboardNotifications()
        StreamManager.shared.onMessageRecieve = { [weak self] (message) in
            self?.dataSource.append(message)
            self?.collectionView.reloadData()
        }
        StreamManager.shared.onPresenceUpdate = { [weak self] (status) in
            self?.activityLabel.text = status
        }
        fetchMessages()
    }
    
    func fetchMessages() {
        guard let reciepent = reciept else { return }
        guard let context = StreamManager.shared.messageArchiving?.mainThreadManagedObjectContext else { return }
        let fetchRequest = NSFetchRequest<XMPPMessageArchiving_Message_CoreDataObject>(entityName: "XMPPMessageArchiving_Message_CoreDataObject")
        let predicate = NSPredicate(format: "bareJidStr = %@", reciepent.userName)
        fetchRequest.predicate = predicate
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let messages = try context.fetch(fetchRequest)
            print(messages)
            let toMessages = messages.compactMap({$0.message.body})
            let actor = messages.compactMap({$0.message.attributeStringValue(forName: "to")})
            let merged = zip(actor, toMessages).compactMap({$0.0 + ": " + $0.1})
            self.dataSource = merged
            self.collectionView.reloadData()
        } catch {
            print(error)
        }
        
    }
    
    func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "ChatCell", bundle: nil), forCellWithReuseIdentifier: "ChatCell")
    }
    
    func keyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { (noti) in
            guard let keyboardFrame = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self.bottomConstraint.constant = -keyboardFrame.height
            self.view.layoutIfNeeded()
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { (_) in
            self.bottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.bool(forKey: "isRegistered") {
            let loginViewController = storyboard?.instantiateViewController(withIdentifier: "LoginRegisterViewController") as! LoginRegisterViewController
            self.present(loginViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func send(_ sender: UIButton) {
        guard let message = self.textView.text,
            let reciept = reciept else { return }
        let userId = XMPPJID(string: reciept.userName)
        let xMessage = XMPPMessage(type: "chat", to: userId)
        xMessage.addBody(message)
        StreamManager.shared.stream.send(xMessage)
        let presence = XMPPPresence(type: "available", to: userId)
        presence.addNick("")
        StreamManager.shared.stream.send(presence)
        self.textView.text = nil
    }
}

extension ViewController: UICollectionViewDelegate {
    
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.dataSource[indexPath.item]
        let atts: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let maxSize = CGSize(width: collectionView.frame.width - 80, height: CGFloat.infinity)
        var size = (item as NSString).boundingRect(with: maxSize, options: [.usesFontLeading, .usesLineFragmentOrigin, .usesDeviceMetrics], attributes: atts, context: nil).size
        size.height += 16
        return CGSize(width: collectionView.frame.width - 80, height: size.height)
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatCell", for: indexPath) as? ChatCell else { return UICollectionViewCell() }
        cell.textLabel.preferredMaxLayoutWidth = collectionView.frame.width
        cell.configure(with: dataSource[indexPath.item])
        return cell
    }
}

extension ViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let reciept = reciept else { return false }
        let presence = XMPPPresence(type: "available", to: XMPPJID(string: reciept.userName))
        presence.addNick("Typing...")
        StreamManager.shared.stream.send(presence)
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        guard let reciept = reciept else { return }
        let presence = XMPPPresence(type: "available", to: XMPPJID(string: reciept.userName))
        presence.addNick("Available")
        StreamManager.shared.stream.send(presence)
    }
}
