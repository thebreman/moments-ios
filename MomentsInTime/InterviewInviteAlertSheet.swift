//
//  InterviewInviteAlertSheet.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let TITLE_FACEBOOK_ACTION = "Ask on Facebook"
private let TITLE_MESSAGE_ACTION = "Message..."
private let TITLE_CANCEL = "Cancel"
private let COPY_MESSAGE_INVITE_INTERVIEW = "Hey I think you have a story to tell. Want to share it on the Moments in Time app?"
private let APP_LINK = "https://itunes.apple.com/us/app/moments-in-time/id1236516374"

class InterviewInviteAlertSheet: NSObject
{
    var completionHandler: AlertCompletion?
    
    func showFrom(viewController: UIViewController, sender: UIView, completion: AlertCompletion? = nil)
    {
        self.completionHandler = completion
        
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        let facebookAction = UIAlertAction(title: TITLE_FACEBOOK_ACTION, style: .default) { _ in
            self.handleFacebookInvite(withViewController: viewController)
        }
        controller.addAction(facebookAction)
        
        let messageAction = UIAlertAction(title: TITLE_MESSAGE_ACTION, style: .default) { _ in
            self.handleMessageInvite(withViewController: viewController, sender: sender)
        }
        controller.addAction(messageAction)
        
        let cancelAction = UIAlertAction(title: TITLE_CANCEL, style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        viewController.present(controller, animated: true, completion: nil)
    }
    
    private func handleFacebookInvite(withViewController presenter: UIViewController)
    {
        let comingSoon = ComingSoonAlertView()
        comingSoon.showFrom(viewController: presenter)
    }
    
    private func handleMessageInvite(withViewController presenter: UIViewController, sender: UIView)
    {
        guard let appLink = URL(string: APP_LINK) else { return }
        
        //present UIActivityViewController,
        //must be popover for iPad:
        let message = COPY_MESSAGE_INVITE_INTERVIEW
        let link = appLink
        let controller = UIActivityViewController(activityItems: [message, link], applicationActivities: nil)
        
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        presenter.present(controller, animated: true, completion: nil)
    }
}
