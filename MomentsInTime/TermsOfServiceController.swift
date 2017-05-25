//
//  TermsOfServiceController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/24/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

typealias TermsOfServiceSuccessCompletion = () -> Void

class TermsOfServiceController: UIViewController
{
    //called after we dismiss after successful agreement to terms:
    var successCompletionHandler: TermsOfServiceSuccessCompletion?
    
    //MARK: Actions

    @IBAction func handleAgree(_ sender: UIBarButtonItem)
    {
        let acceptAlertView = TermsOfServiceAcceptAlertView()
       
        //only dismiss if user agrees to Terms and Conditions:
        acceptAlertView.showFrom(viewController: self) { success in
            if success {
                self.presentingViewController?.dismiss(animated: true) { _ in
                    self.successCompletionHandler?()
                }
            }
        }
    }
}
