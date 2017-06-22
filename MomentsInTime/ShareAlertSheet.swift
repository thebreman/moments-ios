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
private let MESSAGE_SHARE = "Check out this story on Moments in Time!"
private let MESSAGE_SHARE_LOCAL = "Check out the story I'm making for Moments in Time!"
private let MESSAGE_DOWNLOAD = "Download the Moments In Time app from any app store."

class ShareAlertSheet: NSObject
{
    var moment: Moment?
    var completionHandler: AlertCompletion?
    
    func showFrom(viewController: UIViewController, sender: UIView, moment: Moment, completion: AlertCompletion? = nil)
    {
        self.moment = moment
        self.completionHandler = completion
        
        //We might add the commented out flow back in:
        //for now just handleMessageShare:
        
//        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        controller.popoverPresentationController?.sourceView = sender
//        controller.popoverPresentationController?.sourceRect = sender.bounds
//        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
//        
//        let facebookAction = UIAlertAction(title: TITLE_FACEBOOK_ACTION, style: .default) { _ in
//            self.handleFacebookShare(withViewController: viewController)
//        }
//        controller.addAction(facebookAction)
//        
//        let messageAction = UIAlertAction(title: TITLE_MESSAGE_ACTION, style: .default) { _ in
            self.handleMessageShare(withViewController: viewController, sender: sender)
//        }
//        controller.addAction(messageAction)
//        
//        let cancelAction = UIAlertAction(title: TITLE_CANCEL, style: .cancel, handler: nil)
//        controller.addAction(cancelAction)
//        
//        viewController.present(controller, animated: true, completion: nil)
    }
    
    private func handleFacebookShare(withViewController presenter: UIViewController)
    {
        let comingSoon = ComingSoonAlertView()
        comingSoon.showFrom(viewController: presenter)
    }
    
    private func handleMessageShare(withViewController presenter: UIViewController, sender: UIView)
    {
        
        // make sure we have a video link:

        let videoURL : URL
        var message = MESSAGE_SHARE
        let downloadPrompt = MESSAGE_DOWNLOAD
        
        // check if we have a video link
        if let videoLinkString = self.moment?.video?.videoLink, let videoLink = URL(string: videoLinkString)
        {
            videoURL = videoLink
        }
        else if let localVideoUrl = self.moment?.video?.localPlaybackURL
        {   // if not, use the local file url
            videoURL = localVideoUrl
            // and update the message
            message = MESSAGE_SHARE_LOCAL
        }
        else // if not, bail
        {
            return
        }
        
        //present UIActivityViewController,
        //must be popover for iPad:
        let controller = UIActivityViewController(activityItems: [message, videoURL, downloadPrompt], applicationActivities: nil)
        
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        presenter.present(controller, animated: true, completion: nil)
    }
}

