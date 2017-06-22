//
//  UploadConfirmationAlertView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 6/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let COPY_TITLE_CONFIRM_UPLOAD = "Show the world?"
private let COPY_MESSAGE_CONFIRM_UPLOAD = "By submitting this video you’re allowing Moments In Time to share this video to the public. Is that okay?"
private let COPY_TITLE_YES = "Yes"
private let COPY_TITLE_NO = "No"

typealias AlertBooleanCompletion = (Bool) -> Void

class UploadConfirmationAlertView: NSObject
{
    var completionHandler: AlertBooleanCompletion?
    
    func showFrom(presenter: UIViewController, completion: AlertBooleanCompletion? = nil)
    {
        self.completionHandler = completion
        
        let controller = UIAlertController(title: COPY_TITLE_CONFIRM_UPLOAD, message: COPY_MESSAGE_CONFIRM_UPLOAD, preferredStyle: .alert)
        
        let affirmativeAction = UIAlertAction(title: COPY_TITLE_YES, style: .default) { _ in
            self.completionHandler?(true)
        }
        controller.addAction(affirmativeAction)
        controller.preferredAction = affirmativeAction
        
        let negativeAction = UIAlertAction(title: COPY_TITLE_NO, style: .cancel) { _ in
            self.completionHandler?(false)
        }
        controller.addAction(negativeAction)
        
        presenter.present(controller, animated: true, completion: nil)
    }
}
