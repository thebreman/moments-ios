//
//  CommunityMomentOptionsAlertSheet.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import MessageUI

private let TITLE_SHARE_ACTION = "Share"
private let TITLE_REPORT_ACTION = "Report"
private let TITLE_CANCEL = "Cancel"
let EMAIL_FEEDBACK = "justinmilrad@gmail.com"
private let EMAIL_FEEDBACK_SUBJECT = "Moment Video Report"
private let EMAIL_FEEDBACK_BODY = "Hello, I would like to report this video"

class CommunityMomentOptionsAlertSheet: NSObject, MFMailComposeViewControllerDelegate
{
    var moment: Moment?
    var allowsSharing = false
    var completionHandler: AlertCompletion?
    
    private let assistant = Assistant()
    
    func showFrom(viewController: UIViewController, sender: UIView, forMoment moment: Moment, completion: AlertCompletion? = nil)
    {
        self.moment = moment
        self.completionHandler = completion
        
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        if self.allowsSharing {
            let shareAction = UIAlertAction(title: TITLE_SHARE_ACTION, style: .default) { _ in
                self.handleShare(withViewController: viewController, sender: sender)
            }
            controller.addAction(shareAction)
        }
        
        let reportAction = UIAlertAction(title: TITLE_REPORT_ACTION, style: .destructive) { _ in
            self.handleReport(withViewController: viewController, sender: sender, forMoment: moment)
        }
        controller.addAction(reportAction)
        
        let cancelAction = UIAlertAction(title: TITLE_CANCEL, style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        viewController.present(controller, animated: true, completion: nil)
    }
    
    private func handleShare(withViewController presenter: UIViewController, sender: UIView)
    {
        guard let momentToShare = self.moment else { return }
        
        let shareSheet = ShareAlertSheet()
        shareSheet.showFrom(viewController: presenter, sender: sender, moment: momentToShare)
    }
    
    private func handleReport(withViewController presenter: UIViewController, sender: UIView, forMoment moment: Moment)
    {
        guard let videoLink = moment.video?.videoLink else { return }
        
        self.assistant.handleEmail(toRecipients: [EMAIL_FEEDBACK], subject: EMAIL_FEEDBACK_SUBJECT, message: "\(EMAIL_FEEDBACK_BODY): \(videoLink)\n\n", presenter: presenter)
    }
}
