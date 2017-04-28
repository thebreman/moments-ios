//
//  KeyboardWrangling.swift
//  GoChat
//
//  Created by Andrew Ferrarone on 12/3/16.
//  Copyright © 2016 Andrew Ferrarone. All rights reserved.
//

import UIKit

typealias UIKeyboardAnimationBlock = ( (_ keyboardHeight:CGFloat, _ keyboardWindowY:CGFloat) -> Void )

@objc protocol KeyboardMover
{
    @objc func keyboardMoved(notification:Notification)
}

extension NSObject // convenience method for listening to keyboard events
{
    func listenForKeyboardNotifications(shouldListen: Bool)
    {
        if shouldListen
        {
            NotificationCenter.default.addObserver(self, selector: #selector(KeyboardMover.keyboardMoved), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        }
        else
        {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        }
    }
}

extension UIView
{
    class func animateWithKeyboardNotification(notification:Notification, animations: UIKeyboardAnimationBlock)
    {
        // Coordinate the time and curve of the keyboard, as indicated by the notification options
        UIView.beginAnimations("MoveKeyboard", context:nil)
        UIView.setAnimationDelegate(self)
        UIView.setAnimationDuration((notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue)
        UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: (notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue)!)
        UIView.setAnimationBeginsFromCurrentState(true);
        
        // find the keyboards height and Y position on the main window
        let windowHeight = UIApplication.shared.keyWindow!.bounds.size.height
        let keyboardRectValue = notification.userInfo![UIKeyboardFrameEndUserInfoKey]
        let keyboardFrame = (keyboardRectValue as! NSValue).cgRectValue
        let keyboardOriginY = keyboardFrame.origin.y
        var keyboardHeight = keyboardFrame.size.height
        
        // if the keyboard is at some stupid number, its offscreen
        if (keyboardOriginY >= windowHeight) {
            keyboardHeight = 0;
        }
        
        // actually run the changes
        animations(keyboardHeight, keyboardOriginY);
        
        UIView.commitAnimations()
    }
}

