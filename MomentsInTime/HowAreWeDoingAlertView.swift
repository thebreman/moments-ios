//
//  HowAreWeDoingAlertView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/19/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import MessageUI

let appURL = "itms-apps://itunes.apple.com/app/id1236516374"

private let COPY_TITLE_HOW_ARE_WE_DOING = "We're glad you're here."
private let COPY_MESSAGE_HOW_ARE_WE_DOING = "We want this to be a warm and enriching community, and that takes feedback from you. How are we doing?"
private let COPY_TITLE_I_LOVE_IT = "I LOVE IT 🙏🏼"
private let COPY_TITLE_PROBLEM = "I have a problem"
private let COPY_TITLE_CANCEL = "Cancel"

private let COPY_TITLE_RATING = "Thanks for the Love!"
private let COPY_MESSAGE_RATING = "Would you like to share your love and spread the word by giving us a 5-Star rating in the App Store?"
private let COPY_TITLE_RATING_BUTTON_OK = "Yes!"
private let COPY_TITLE_RATING_BUTTON_NOT_NOW = "Not now"

private let EMAIL_FEEDBACK_SUBJECT = "Moments In Time Feedback"
private let EMAIL_FEEDBACK_BODY = "Hello, I have a problem, \n\n"

class HowAreWeDoingAlertView: NSObject
{
    var completionHandler: AlertCompletion?
    
    private let assistant = Assistant()
    
    func showFrom(viewController: UIViewController, completion: AlertCompletion? = nil)
    {
        self.completionHandler = completion
        
        let controller = UIAlertController(title: COPY_TITLE_HOW_ARE_WE_DOING, message: COPY_MESSAGE_HOW_ARE_WE_DOING, preferredStyle: .alert)
        
        let lovinItAction = UIAlertAction(title: COPY_TITLE_I_LOVE_IT, style: .default) { _ in
            
            //handle I LOVE IT 🙏🏼!!!
            self.handleLovinIt(withPresenter: viewController)
        }
        controller.addAction(lovinItAction)
        controller.preferredAction = lovinItAction
        
        let theresAProblemAction = UIAlertAction(title: COPY_TITLE_PROBLEM, style: .default) { _ in
            
            //handle I Have a problem:
            self.handleProblem(withPresenter: viewController)
            
            self.completionHandler?()
            self.completionHandler = nil
        }
        controller.addAction(theresAProblemAction)
        
        let cancelAction = UIAlertAction(title: COPY_TITLE_CANCEL, style: .cancel) { _ in
            self.completionHandler?()
            self.completionHandler = nil
        }
        controller.addAction(cancelAction)
        
        viewController.present(controller, animated: true, completion: nil)
    }
    
    //MARK: Utilities:
    
    private func handleProblem(withPresenter presenter: UIViewController)
    {
        self.assistant.handleEmail(toRecipients: [EMAIL_FEEDBACK], subject: EMAIL_FEEDBACK_SUBJECT, message: EMAIL_FEEDBACK_BODY, presenter: presenter)
    }
    
    private func handleLovinIt(withPresenter presenter: UIViewController)
    {
        //invite user to Rate the app:
        let controller = UIAlertController(title: COPY_TITLE_RATING, message: COPY_MESSAGE_RATING, preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: COPY_TITLE_RATING_BUTTON_OK, style: .default) { _ in
            
            //to send user to the store for ratings....
            guard let url = URL(string: appURL) else {
                self.completionHandler?()
                self.completionHandler = nil
                return
            }
            
            UIApplication.shared.open(url, options: [:]) { success in
                self.completionHandler?()
                self.completionHandler = nil
            }
        }
        controller.addAction(yesAction)
        controller.preferredAction = yesAction
        
        let noAction = UIAlertAction(title: COPY_TITLE_RATING_BUTTON_NOT_NOW, style: .default) { _ in
            self.completionHandler?()
            self.completionHandler = nil
        }
        controller.addAction(noAction)
        
        presenter.present(controller, animated: true, completion: nil)
    }
}
