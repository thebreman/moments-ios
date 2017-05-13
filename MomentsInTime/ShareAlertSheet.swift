//
//  ShareAlertSheet.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let TITLE_FACEBOOK_ACTION = "Share on Facebook"
private let TITLE_MESSAGE_ACTION = "Message..."
private let TITLE_CANCEL = "Cancel"
private let MESSAGE_SHARE = "Hello, checkout this awesome app Moments In Time"
private let APP_LINK = "https://marvelapp.com/fj8ic86/screen/26066627"

class ShareAlertSheet: NSObject
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
            self.handleFacebookShare(withViewController: viewController)
        }
        controller.addAction(facebookAction)
        
        let messageAction = UIAlertAction(title: TITLE_MESSAGE_ACTION, style: .default) { _ in
            self.handleMessageShare(withViewController: viewController, sender: sender)
        }
        controller.addAction(messageAction)
        
        let cancelAction = UIAlertAction(title: TITLE_CANCEL, style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        viewController.present(controller, animated: true, completion: nil)
    }
    
    private func handleFacebookShare(withViewController presenter: UIViewController)
    {
        let comingSoon = ComingSoonAlertView()
        comingSoon.showFrom(viewController: presenter)
    }
    
    private func handleMessageShare(withViewController presenter: UIViewController, sender: UIView)
    {
        //present UIActivityViewController,
        //must be popover for iPad:
        let message = MESSAGE_SHARE
        let link = URL(string: APP_LINK)!
        let controller = UIActivityViewController(activityItems: [message, link], applicationActivities: nil)
        
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        presenter.present(controller, animated: true, completion: nil)
    }
}

