//
//  LoginRegisterViewController.swift
//  EjabberdChat
//
//  Created by Neil Jain on 15/09/18.
//  Copyright © 2018 Neil Jain. All rights reserved.
//

import UIKit

class LoginRegisterViewController: UIViewController {
    
    var currentState: State = .login {
        didSet {
            configureState(currentState)
        }
    }
    
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var stateButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.returnKeyType = .continue
        passwordField.delegate = self
    }
    
    func configureState(_ state: State) {
        switch state {
        case .login:
            self.actionButton.setTitle("Login", for: UIControl.State.normal)
            self.stateButton.setTitle("Register", for: UIControl.State.normal)
        case .register:
            self.stateButton.setTitle("Login", for: UIControl.State.normal)
            self.actionButton.setTitle("Register", for: UIControl.State.normal)
        }
    }
    
    @IBAction func loginAction(_ sender: Any) {
        guard let userName = userNameField.text, let password = passwordField.text else { return }
        switch currentState {
        case .login:
            StreamManager.shared.creds = StreamManager.LoginCreds(
                userName: userName,
                password: password
            )
            StreamManager.shared.onLogin = { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        case .register:
            break
        }
    }
    
    @IBAction func stateButtonAction(_ sender: Any) {
        currentState.toggle()
    }
    
    
}

extension LoginRegisterViewController {
    enum State {
        case login
        case register
        
        mutating func toggle() {
            switch self {
            case .login:
                self = .register
            case .register:
                self = .login
            }
        }
    }
}

extension LoginRegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}
