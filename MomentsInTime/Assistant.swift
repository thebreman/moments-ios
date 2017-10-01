//
//  Assistant.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import UserNotifications
import MessageUI

private let TITLE_DEVICE_CANT_MAIL = "Oh No!"
private let MESSAGE_DEVICE_CANT_MAIL = "This device cannot send mail."
private let MESSAGE_DEVICE_CANT_SMS = "This device cannot send messages."

class Assistant: NSObject, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate
{
    //fires off local notifications for background session debugging:
    class func triggerNotification(withTitle title: String, message: String, delay: TimeInterval)
    {
        //local notification
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound];
        
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Permission to send notifications denied")
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default()
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "debug", content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if let error = error {
                print(error)
            }
        }
    }

    class func removeImageFromDisk(atRelativeURLString relativeURLString: String)
    {
        if let images = FileManager.getImagesDirectory() {
            
            let pathToRemove = images.appendingPathComponent(relativeURLString)
            
            do {
                try FileManager.default.removeItem(at: pathToRemove)
                print("removed image!")
            }
            catch let error {
                print("unable to remove image from disk: \(error)")
            }
        }
    }
    
    class func removeVideoFromDisk(atRelativeURLString relativeURLString: String, completion: ((Bool) -> Void)?)
    {
        if let videos = FileManager.getVideosDirectory() {
            
            let pathToRemove = videos.appendingPathComponent(relativeURLString)
            
            do {
                try FileManager.default.removeItem(at: pathToRemove)
                print("removed video!")
                completion?(true)
                return
            }
            catch let error {
                print("unable to remove video from disk: \(error)")
                completion?(false)
                return
            }
        }
    }
    
    class func loadImageFromDisk(withRelativeUrlString urlString: String) -> UIImage?
    {
        if let images = FileManager.getImagesDirectory() {
            
            let imageURL = images.appendingPathComponent(urlString)
            
            do {
                let imageData = try Data.init(contentsOf: imageURL, options: [])
                return UIImage(data: imageData)
            }
            catch let error {
                print("\nunable to load image from disk: \(error)")
            }
        }
        else {
            print("\nunable to get imageDirectory")
        }
        
        return nil
    }
    
    //returns the relative path for the persisted image
    class func persistImage(_ image: UIImage, compressionQuality: CGFloat, atRelativeURLString urlString: String?) -> String?
    {
        var relativeImageFileName: String
        
        //if we have previously saved an image we want to overwrite it:
        //first get documents directory(this could change so we need to get it every time and only store the relative path)
        if let uRLString = urlString {
            relativeImageFileName = uRLString
        }
        else {
            
            //otherwise create a url:
            let imageName = UUID().uuidString
            relativeImageFileName = "\(imageName).jpeg"
        }
        
        guard let imageData = UIImageJPEGRepresentation(image, compressionQuality) else {
            return nil
        }
        
        if let imageDirectory = FileManager.getImagesDirectory() {
            
            do {
                try imageData.write(to: imageDirectory.appendingPathComponent(relativeImageFileName), options: [.atomic])
                return relativeImageFileName
            }
            catch let error {
                print("\nunable to write image to disk: \(error)")
            }
        }
        else {
            print("\nunable to get imageDirectory")
        }
        
        return nil
    }
    
    private var backgroundID: UIBackgroundTaskIdentifier? = nil
    
    func copyVideo(withURL url: URL, completion: @escaping (String?) -> Void)
    {
        //setup background task to ensure that there is enough time to write the file:
        if UIDevice.current.isMultitaskingSupported {
            self.backgroundID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        }
        
        //need .mp4 for AVPlayer to recognize the url:
        let relativeVideoName = "\(UUID().uuidString).mp4"
        
        if let videoDirectory = FileManager.getVideosDirectory() {
            
            //copy file asynchronously:
            DispatchQueue.global(qos: .userInitiated).async {
                
                do {
                    try FileManager.default.copyItem(at: url, to: videoDirectory.appendingPathComponent(relativeVideoName))
                    
                    DispatchQueue.main.async {
                        completion(relativeVideoName)
                        self.endBackgroundTask()
                        return
                    }
                }
                catch let error {
                    print("\nunable to copy video to disk: \(error)")
                    completion(nil)
                    self.endBackgroundTask()
                    return
                }
            }
        }
    }
    
    //MARK: Email
    
    private var emailCompletion: (() -> Void)?
    
    func handleEmail(toRecipients recipients: [String], subject: String, message: String, presenter: UIViewController, completion: (() -> Void)? = nil)
    {
        self.emailCompletion = completion
        
        // send the email if possible:
        if MFMailComposeViewController.canSendMail() {
            
            let mailComposer = MFMailComposeViewController()
            
            // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property:
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(recipients)
            mailComposer.setSubject(subject)
            mailComposer.setMessageBody(message, isHTML: false)
            mailComposer.view.tintColor = UIColor.mitActionblue
            
            presenter.present(mailComposer, animated: true, completion: nil)
        }
        else {
            UIAlertController.explain(withPresenter: presenter, title: TITLE_DEVICE_CANT_MAIL, message: MESSAGE_DEVICE_CANT_MAIL)
        }
    }
    
    //MARK: MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.contentViewController.dismiss(animated: true) {
            self.emailCompletion?()
        }
    }
    
    //MARK: SMS
    
    private var smsCompletion: (() -> Void)?
    
    func handleSMS(toRecipients recipients: [String], body: String, presenter: UIViewController, completion: (() -> Void)? = nil)
    {
        self.smsCompletion = completion
        
        //send sms if possible:
        if MFMessageComposeViewController.canSendText() {
            
            let smsComposer = MFMessageComposeViewController()
            smsComposer.messageComposeDelegate = self
            smsComposer.recipients = recipients
            smsComposer.body = body
            smsComposer.view.tintColor = UIColor.mitActionblue
            
            presenter.present(smsComposer, animated: true, completion: nil)
        }
        else {
            UIAlertController.explain(withPresenter: presenter, title: TITLE_DEVICE_CANT_MAIL, message: MESSAGE_DEVICE_CANT_SMS)
        }
    }
    
    //MARK: MFMessageComposeViewControllerDelegate
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.contentViewController.dismiss(animated: true) {
            self.smsCompletion?()
        }
    }
    
    //MARK: Utilities:
    
    private func endBackgroundTask()
    {
        //end the backgroundTask:
        if let currentBackgroundID = self.backgroundID {
            
            self.backgroundID = UIBackgroundTaskInvalid
            
            if currentBackgroundID != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundID)
                self.backgroundID = nil
            }
        }
    }
}
