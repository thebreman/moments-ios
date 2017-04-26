//
//  LoginController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/24/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore
import PureLayout

@IBDesignable
class LoginController: UIViewController
{
    lazy var loginButton: LoginButton = {
        let loginButton = LoginButton(readPermissions: [.publicProfile, .userFriends])
        loginButton.delegate = self
        return loginButton
    }()
    
    var loginCompletionHandler: (() -> Void)?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setup()
    }
    
    private func setup()
    {
        self.view.addSubview(loginButton)
        self.loginButton.autoCenterInSuperview()
    }
}

extension LoginController: LoginButtonDelegate
{
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult)
    {
        //if success, call completion handler otherwise don't let user in (for now)...
        switch result {
        case .success: self.loginCompletionHandler?()
        default: break
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton)
    {
        print("user did log out")
    }
}

