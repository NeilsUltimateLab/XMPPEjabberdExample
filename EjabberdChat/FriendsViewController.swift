//
//  FriendsViewController.swift
//  EjabberdChat
//
//  Created by Neil Jain on 20/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import UIKit
import XMPPFramework

class User {
    var userName: String = ""
    var status: String?
    var presence: String?
}

extension User {
    var jid: XMPPJID? {
        return XMPPJID(string: userName)
    }
}

class FriendsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var dataSource: [User] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchRosters()
    }
    
    func setupTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
    }
    
    func fetchRosters() {
        StreamManager.shared.onRosterRecieve = { [weak self] (users) in
            self?.dataSource = users
        }
    }

}

extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = dataSource[indexPath.row]
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ChatViewController
        nextVC.recipient = user
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}

extension FriendsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "cellId")
        cell.textLabel?.text = dataSource[indexPath.row].userName
        cell.detailTextLabel?.text = dataSource[indexPath.row].status
        return cell
    }
}
