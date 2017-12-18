//
//  TermsOfServiceController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/24/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

typealias TermsOfServiceSuccessCompletion = () -> Void

class TermsOfServiceController: WebViewController, TermsPrivacyHandler
{
    var successCompletionHandler: TermsOfServiceSuccessCompletion?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let termsOfUseFileURL = MITDocuments.termsOfUse.localURL {
            self.loadLocalURL(url: termsOfUseFileURL)
        }
    }
    
//MARK: Actions

    @IBAction func handleAgree(_ sender: UIBarButtonItem)
    {
        let acceptAlertView = TermsOfServiceAcceptAlertView()
       
        //only dismiss if user agrees to Terms and Conditions:
        acceptAlertView.showFrom(viewController: self) { success in
            
            if success {
                self.successCompletionHandler?()
            }
        }
    }
}
