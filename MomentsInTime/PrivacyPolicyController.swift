//
//  PrivacyPolicyController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 12/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class PrivacyPolicyController: WebViewController, TermsPrivacyHandler
{
    var successCompletionHandler: TermsOfServiceSuccessCompletion?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let privacyPolicyFileURL = MITDocuments.privacyPolicy.localURL {
            self.loadLocalURL(url: privacyPolicyFileURL)
        }
    }
    
//MARK: Actions
    
    @IBAction func handleAgree(_ sender: UIBarButtonItem)
    {
        let acceptAlertView = PrivacyPolicyAcceptAlertView()
        
        //only dismiss uf user agrees to Privacy Policy:
        acceptAlertView.showFrom(viewController: self) { success in
            
            if success {
                self.presentingViewController?.dismiss(animated: true) {
                    self.successCompletionHandler?()
                }
            }
        }
    }
}



