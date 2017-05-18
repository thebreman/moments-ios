//
//  Assistant.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import UserNotifications

class Assistant
{
    //fires off local notifications for background session debugging
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
                completion?(true)
            }
            catch let error {
                print("unable to remove video from disk: \(error)")
                completion?(false)
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
                        self.endBackgroundTask()
                        completion(relativeVideoName)
                    }
                }
                catch let error {
                    print("\nunable to copy video to disk: \(error)")
                }
            }
        }
        
        self.endBackgroundTask()
        completion(nil)
    }
    
    private func endBackgroundTask()
    {
        //end the backgroundTask:
        if let currentBackgroundID = self.backgroundID {
            self.backgroundID = UIBackgroundTaskInvalid
            if currentBackgroundID != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundID)
            }
        }
    }
}
