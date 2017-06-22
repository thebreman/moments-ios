//
//  ContactInviteAlert.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 6/19/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import Contacts
import MessageUI

//keep spaces in these:
private let COPY_TITLE_INVITE_PROMPT_START = "Would you like to message "
private let COPY_TITLE_INVITE_PROMPT_END = " about the interview?"

private let COPY_TITLE_YES_INVITE = "Yes"
private let COPY_TITLE_NO_INVITE = "No thanks"

private let COPY_TITLE_EMAIL = "Email"
private let COPY_TITLE_SMS = "Text"
private let COPY_TITLE_CANCEL_INVITE = "Cancel"

private let COPY_MESSAGE_INVITE = "Hi, I think you’d be a great candidate to interview for the Moments in Time Project. The videos are short 1-4 minute videos telling stories. It’s quick and easy. When would you be available? \nYou can check out the app at {store_url}"
private let COPY_SUBJECT_EMAIL = "Moments In Time Interview"

class ContactInviteAlert: NSObject
{
    var completionHandler: AlertCompletion?
    var topic: Topic?
    
    //need to add optional topic support too:
    func showFrom(presenter: UIViewController, withContact contact: CNContact, name: String, topic: Topic?, completion: AlertCompletion? = nil)
    {
        self.completionHandler = completion
        self.topic = topic
        
        let controller = UIAlertController(title: self.contactInviteTitle(forName: name), message: nil, preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: COPY_TITLE_YES_INVITE, style: .default) { _ in
            self.handleYes(withPresenter: presenter, contact: contact)
        }
        controller.addAction(yesAction)
        controller.preferredAction = yesAction
        
        let noAction = UIAlertAction(title: COPY_TITLE_NO_INVITE, style: .cancel) { _ in
            self.completionHandler?()
        }
        controller.addAction(noAction)
        
        presenter.present(controller, animated: true, completion: nil)
    }
    
    //MARK: Private

    private var contactInviteMessage: String {
        return COPY_MESSAGE_INVITE.replacingOccurrences(of: "{store_url}", with: appURL)
    }
    
    private func contactInviteTitle(forName name: String) -> String
    {
        return COPY_TITLE_INVITE_PROMPT_START + "\(name.trimmed())" + COPY_TITLE_INVITE_PROMPT_END
    }
    
    private let assistant = Assistant()
    
    private func handleYes(withPresenter presenter: UIViewController, contact: CNContact)
    {
        //present alert sheet for email or sms options:
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let emailAction = UIAlertAction(title: COPY_TITLE_EMAIL, style: .default) { _ in
            self.handleEmail(withPresenter: presenter, contact: contact)
        }
        controller.addAction(emailAction)
        
        let smsAction = UIAlertAction(title: COPY_TITLE_SMS, style: .default) { _ in
            self.handleSMS(withPresenter: presenter, contact: contact)
        }
        controller.addAction(smsAction)
        controller.preferredAction = smsAction
        
        let cancelAction = UIAlertAction(title: COPY_TITLE_CANCEL_INVITE, style: .cancel) { _ in
            self.completionHandler?()
        }
        controller.addAction(cancelAction)
        
        presenter.present(controller, animated: true, completion: nil)
    }
    
    private func handleEmail(withPresenter presenter: UIViewController, contact: CNContact)
    {
        var emails = [String]()
        
        //try and scrape contact for email:
        if !contact.emailAddresses.isEmpty {
            if let firstEmail = contact.emailAddresses.first {
                emails.append(firstEmail.value as String)
            }
        }
        
        let emailMessage = self.contactInviteMessage
        
        self.assistant.handleEmail(toRecipients: emails, subject: COPY_SUBJECT_EMAIL, message: emailMessage, presenter: presenter) {
            self.completionHandler?()
        }
    }
    
    private func handleSMS(withPresenter presenter: UIViewController, contact: CNContact)
    {
        var phoneNumber: CNPhoneNumber? = nil
        var recipients = [String]()
        
        //try and scrape contact for numbers:
        if !contact.phoneNumbers.isEmpty {
            
            //try and grab iPhone:
            contact.phoneNumbers.forEach {
                if $0.label == CNLabelPhoneNumberiPhone {
                    phoneNumber = $0.value
                }
            }
            
            //if nothing, try and grab mobile:
            if phoneNumber == nil {
                contact.phoneNumbers.forEach {
                    if $0.label == CNLabelPhoneNumberMobile {
                        phoneNumber = $0.value
                    }
                }
            }
            
            //otherwise just grab the first available:
            if phoneNumber == nil {
                phoneNumber = contact.phoneNumbers.first?.value
            }
        }
        
        if let selectedNumber = phoneNumber {
            recipients.append(selectedNumber.stringValue)
        }
        
        let smsMessage = self.contactInviteMessage
        
        self.assistant.handleSMS(toRecipients: recipients, body: smsMessage, presenter: presenter) {
            self.completionHandler?()
        }
    }
}
