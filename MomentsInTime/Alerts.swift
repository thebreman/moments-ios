//
//  Alerts.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

extension UIAlertController
{
    static func showDeleteSheet(withPresenter presenter: UIViewController, sender: UIView, title: String?, itemToDeleteTitle: String?, deleteHandler: ((UIAlertAction) -> Void)? = nil)
    {
        let controller = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        let deleteAction = UIAlertAction(title: COPY_TITLE_BUTTON_DELETE + (" ") + (itemToDeleteTitle ?? ""), style: .destructive, handler: deleteHandler )
        controller.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: COPY_TITLE_BUTTON_CANCEL, style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        
        presenter.present(controller, animated: true, completion: nil)
    }
    
    static func explain(withPresenter presenter: UIViewController, title: String?, message: String?)
    {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        controller.addAction(okAction)
        
        presenter.present(controller, animated: true, completion: nil)
    }
    
    static func confirm(withPresenter presenter: UIViewController, message: String?, completion: @escaping (Void) -> Void)
    {
        let title = "Just making sure"
        let affirmative = "do it"
        let negative = "nevermind"
        
        self.ask(withPresenter: presenter, title: title, message: message, affirmative: affirmative, negative: negative, completion: completion)
    }
    
    static func ask(withPresenter presenter: UIViewController?, title: String?, message: String?, affirmative: String, negative: String, completion: @escaping (Void) -> Void)
    {
        guard presenter != nil else { return }
        
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: affirmative, style: .default) { action in
            completion()
        }
        controller.addAction(confirmAction)
        
        let denyAction = UIAlertAction(title: negative, style: .default) { action in
            completion()
        }
        controller.addAction(denyAction)
        
        presenter!.present(controller, animated: true, completion: nil)
    }
    
    //presents UIAlertController w/ OK button and optional Settings and okButton button:
    static func alertUser(withPresenter presenter: UIViewController, title: String?, message: String?, okButton: Bool, settingsButton: Bool)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if settingsButton {
            alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            }))
        }
        
        if okButton {
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        }
        
        presenter.present(alertController, animated: true, completion: nil)
    }
}
