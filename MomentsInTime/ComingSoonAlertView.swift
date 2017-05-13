//
//  ComingSoonAlertView.swift
//  MomentsInTime
//
//  Created by Brian on 5/12/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let ALERT_TITLE = "Coming Soon"
private let ALERT_MESSAGE = "Feature in development. It will be ready in no time!"
private let ALERT_CONFIRM = "Cool!"

typealias ComingSoonAlertCompletion = () -> Void

class ComingSoonAlertView: NSObject
{
    var completionClosure: ComingSoonAlertCompletion?
    
    func showFrom(viewController: UIViewController, completion: ComingSoonAlertCompletion? = nil)
    {
        self.completionClosure = completion
        
        let alertController = UIAlertController(title: ALERT_TITLE, message: ALERT_MESSAGE, preferredStyle: UIAlertControllerStyle.alert)
        
        let okayButton = UIAlertAction(title: ALERT_CONFIRM, style: UIAlertActionStyle.default) { _ in
            // call the completion after dismissing
            self.completionClosure?()
            self.completionClosure = nil
        }
        
        alertController.addAction(okayButton)
        
        viewController.present(alertController, animated: true, completion: nil)
    }
    
}
