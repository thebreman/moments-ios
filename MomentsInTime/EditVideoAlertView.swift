//
//  EditVideoAlertView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 6/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let COPY_TITLE_EDIT_VIDEO_ALERT = "Edit until your heart is content"
private let COPY_MESSAGE_EDIT_VIDEO_ALERT = "The video has been saved to your camera roll. You can edit the video with your favorite tools and update this Moment with the new video when you're ready. Nothing will be uploaded until you say so."
private let COPY_TITLE_BUTTON_CAMERA_ROLL = "Select new video"


class EditVideoAlertView: NSObject
{
    var completionHandler: AlertCompletion?
    
    func showFrom(presenter: UIViewController, completion: AlertCompletion? = nil)
    {
        self.completionHandler = completion
        
        let controller = UIAlertController(title: COPY_TITLE_EDIT_VIDEO_ALERT, message: COPY_MESSAGE_EDIT_VIDEO_ALERT, preferredStyle: .alert)
        
        let cameraRollAction = UIAlertAction(title: COPY_TITLE_BUTTON_CAMERA_ROLL, style: .default) { _ in
            self.completionHandler?()
        }
        controller.addAction(cameraRollAction)
        
        let okAction = UIAlertAction(title: COPY_TITLE_BUTTON_OK, style: .cancel, handler: nil)
        controller.addAction(okAction)
        controller.preferredAction = okAction
        
        presenter.present(controller, animated: true, completion: nil)
    }
}
