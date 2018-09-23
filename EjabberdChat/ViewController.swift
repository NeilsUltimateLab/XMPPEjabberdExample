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
    @IBOutlet var keyboardInputView: KeyboardInputView!
    
    lazy var titleView: ChatTitleView? = {
        return ChatTitleView.initFromNib()
    }()
    
    var recipient: User?
    
    var dataSource: [String] = []
    var sizeCache: [IndexPath: CGSize] = [:]
    
    lazy var attribute: Attributes = {
        let atts = Attributes(font: UIFont.systemFont(ofSize: 17),
                              maximumWidth: self.collectionView.frame.width - 80,
                              maximumHeight: CGFloat.infinity,
                              textContentInsets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        return atts
    }()
    
    lazy var fetchResultsController: NSFetchedResultsController<ArchivedMessage>? = {
        guard let recipient = recipient else { return nil }
        guard let context = StreamManager.shared.messageArchiving?.mainThreadManagedObjectContext else { return nil }
        let fetchRequest = NSFetchRequest<ArchivedMessage>(entityName: "XMPPMessageArchiving_Message_CoreDataObject")
        let predicate = NSPredicate(format: "bareJidStr = %@", recipient.userName)
        fetchRequest.predicate = predicate
        fetchRequest.returnsObjectsAsFaults = false
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let controller = NSFetchedResultsController<ArchivedMessage>(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "timestamp", cacheName: nil)
        controller.delegate = self
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        keyboardNotifications()
        StreamManager.shared.onMessageRecieve = { [weak self] (message) in
            self?.dataSource.append(message)
            self?.collectionView.reloadData()
        }
        StreamManager.shared.onPresenceUpdate = { [weak self] (status) in
            self?.titleView?.updateState(with: status)
        }
        fetchMessages()
        self.navigationItem.titleView = self.titleView
        self.titleView?.configure(with: recipient?.userName ?? "")
        
        self.keyboardInputView.onTextCharacterChange = { [weak self] in
            guard let reciept = self?.recipient else { return }
            StreamManager.shared.update(presence: .typing(to: reciept))
        }
    }
    
    func fetchMessages() {
        guard let reciepent = recipient else { return }
        guard let context = StreamManager.shared.messageArchiving?.mainThreadManagedObjectContext else { return }
        let fetchRequest = NSFetchRequest<ArchivedMessage>(entityName: "XMPPMessageArchiving_Message_CoreDataObject")
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
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumInteritemSpacing = 8
            flowLayout.minimumLineSpacing = 8
            flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
        self.collectionView.register(UINib(nibName: "ChatCell", bundle: nil), forCellWithReuseIdentifier: "ChatCell")
    }
    
    func keyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { (noti) in
            guard let keyboardFrame = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            //self.bottomConstraint.constant = -keyboardFrame.height
            self.collectionView.contentInset.bottom = keyboardFrame.height
            self.view.layoutIfNeeded()
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { (_) in
            self.collectionView.contentInset.bottom = 0
            //self.bottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: nil) { (_) in
            self.scrollToLast(animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.becomeFirstResponder()
        do {
            try fetchResultsController?.performFetch()
            self.collectionView.reloadData()
        } catch {
            print(error)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.bool(forKey: "isRegistered") {
            let loginViewController = storyboard?.instantiateViewController(withIdentifier: "LoginRegisterViewController") as! LoginRegisterViewController
            self.present(loginViewController, animated: true, completion: nil)
        }
        scrollToLast(animated: true)
    }
    
    override var inputAccessoryView: UIView? {
        return self.keyboardInputView
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @IBAction func send(_ sender: UIButton) {
        guard let message = self.keyboardInputView.text,
            let reciept = recipient else { return }
        StreamManager.shared.send(.chat(body: message, to: reciept))
        StreamManager.shared.update(presence: StreamManager.Presence.availableTo(to: reciept))
        self.keyboardInputView.reset()
    }
    
    func scrollToLast(animated: Bool = false) {
        let indexSection = self.collectionView.numberOfSections - 1
        let indexItem = self.collectionView.numberOfItems(inSection: indexSection) - 1
        let indexPath = IndexPath(item: indexItem, section: indexSection)
        self.collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.top, animated: animated)
    }
}

extension ViewController: UICollectionViewDelegate {
    
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let text = self.fetchResultsController?.sections?[indexPath.section].objects?[indexPath.item] as? XMPPMessageArchiving_Message_CoreDataObject else { return .zero }
        let body = text.message.body!
        let height = self.attribute.size(for: body).height
        var width = collectionView.frame.width
        width -= (collectionView.contentInset.left + collectionView.contentInset.right)
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            width -= (flowLayout.sectionInset.left + flowLayout.sectionInset.right)
        }
        return CGSize(width: width, height: height)
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchResultsController?.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatCell", for: indexPath) as? ChatCell else { return UICollectionViewCell() }
        guard let item = fetchResultsController?.sections?[indexPath.section].objects?[indexPath.item] as? ArchivedMessage else { return UICollectionViewCell() }
        let size = attribute.size(for: item.message.body ?? "")
        cell.configure(with: item.message, width: size.width, isOutgoing: item.isOutgoing)
        return cell
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        self.collectionView.reloadData()
        self.scrollToLast(animated: true)
    }
}
