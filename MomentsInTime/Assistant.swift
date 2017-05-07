//
//  Assistant.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class Assistant
{
    class func loadImageFromDisk(withRelativeUrlString urlString: String) -> UIImage?
    {
        let imageURL = FileManager.getDocumentsDirectory().appendingPathComponent(urlString)
        
        do {
            let imageData = try Data.init(contentsOf: imageURL, options: [])
            return UIImage(data: imageData)
        }
        catch let error {
            print("\nunable to load image from disk: \(error)")
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
        
        do {
            try imageData.write(to: FileManager.getDocumentsDirectory().appendingPathComponent(relativeImageFileName), options: [.atomic])
            return relativeImageFileName
        }
        catch let error {
            print("\nunable to write image to disk: \(error)")
        }
        
        return nil
    }
    
    class func removeFileFromDisk(atRelativeURLString relativeURLString: String)
    {
        let documents = FileManager.getDocumentsDirectory()
        let pathToRemove = documents.appendingPathComponent(relativeURLString)
        
        do {
            try FileManager.default.removeItem(at: pathToRemove)
        }
        catch let error {
            print("unable to remove file from disk: \(error)")
        }
    }
    
    private var backgroundID: UIBackgroundTaskIdentifier? = nil
    
    func persistVideo(withURL url: URL) -> String?
    {
        //setup background task to ensure that there is enough time to write the file:
        if UIDevice.current.isMultitaskingSupported {
            self.backgroundID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        }
        
        guard let videoData = try? Data(contentsOf: url) else {
            print("\nunable to get video Data to persist")
            return nil
        }
        
        let relativeVideoName = UUID().uuidString
        
        do {
            try videoData.write(to: FileManager.getDocumentsDirectory().appendingPathComponent(relativeVideoName), options: [.atomic])
            self.endBackgroundTask()
            return relativeVideoName
        }
        catch let error {
            print("\nunable to write video to disk: \(error)")
        }
        
        self.endBackgroundTask()
        return nil
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
