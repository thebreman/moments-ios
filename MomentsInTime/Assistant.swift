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
    class func loadImageFromDisk(withUrlString urlString: String) -> UIImage?
    {
        if let imageURL = URL(string: urlString),
            let imageData = try? Data.init(contentsOf: imageURL, options: []) {
            return UIImage(data: imageData)
        }
        
        return nil
    }
    
    class func persistImage(_ image: UIImage, compressionQuality: CGFloat, atURLString urlString: String?) -> URL?
    {
        var imageFileName: URL
        
        //if we have previously saved an image we want to overwrite it:
        if let uRLString = urlString, let imageFile = URL(string: uRLString) {
            imageFileName = imageFile
        }
        else {
            
            //otherwise create a url:
            let imageName = UUID().uuidString
            imageFileName = FileManager.getDocumentsDirectory().appendingPathComponent("\(imageName).jpeg")
        }
        
        guard let imageData = UIImageJPEGRepresentation(image, compressionQuality) else {
            return nil
        }
        
        try? imageData.write(to: imageFileName)
        return imageFileName
    }
}
