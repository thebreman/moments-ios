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
            print("unable to load image from disk: \(error)")
        }
        
        return nil
    }
    
    class func persistImage(_ image: UIImage, compressionQuality: CGFloat, atURLString urlString: String?) -> String?
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
            try imageData.write(to: FileManager.getDocumentsDirectory().appendingPathComponent(relativeImageFileName))
            return relativeImageFileName
        }
        catch let error {
            print("\n unable to write image to disk: \(error)")
        }
        
        return nil
    }
}
