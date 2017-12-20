//
//  TermsOfServiceAcceptAlertView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/24/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let COPY_TITLE_TERMS = "Terms and Conditions"
private let COPY_MESSAGE_TERMS = "I have read and agree to the Moments In Time Privacy Policy and Terms and Conditions."
private let COPY_TITLE_BUTTON_ACCEPT = "Agree"
private let COPY_TITLE_TERMS_BUTTON_CANCEL = "Cancel"

//true if user accepted terms:
typealias TermsOfServiceAcceptCompletion = (Bool) -> Void

class TermsOfServiceAcceptAlertView: NSObject
{
    var completionHandler: TermsOfServiceAcceptCompletion?
    
    func showFrom(viewController: UIViewController, completion: TermsOfServiceAcceptCompletion? = nil)
    {
        self.completionHandler = completion
        
        let controller = UIAlertController(title: COPY_TITLE_TERMS, message: COPY_MESSAGE_TERMS, preferredStyle: .alert)
        
        let acceptAction = UIAlertAction(title: COPY_TITLE_BUTTON_ACCEPT, style: .default) { _ in
            self.completionHandler?(true)
        }
        
        controller.addAction(acceptAction)
        controller.preferredAction = acceptAction
        
        let cancelAction = UIAlertAction(title: COPY_TITLE_TERMS_BUTTON_CANCEL, style: .cancel) { _ in
            self.completionHandler?(false)
        }
        controller.addAction(cancelAction)
        
        viewController.present(controller, animated: true, completion: nil)
    }
}
