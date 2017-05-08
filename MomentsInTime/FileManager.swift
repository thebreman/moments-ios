//
//  FileManager.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/1/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

extension FileManager
{
    class func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    class func getImagesDirectory() -> URL?
    {
        let documentsDirectory = FileManager.getDocumentsDirectory()
        let imageDirectory = documentsDirectory.appendingPathComponent("momentImages")
        
        if !FileManager.default.fileExists(atPath: imageDirectory.path) {
            
            do {
                try FileManager.default.createDirectory(atPath: imageDirectory.path, withIntermediateDirectories: true, attributes: nil)
                return imageDirectory
            }
            catch let error {
                print("\nunable to create image directory: \(error)")
                return nil
            }
        }
        
        return imageDirectory
    }
    
    class func getVideosDirectory() -> URL?
    {
        let documentsDirectory = FileManager.getDocumentsDirectory()
        let videosDirectory = documentsDirectory.appendingPathComponent("momentVideos")
        
        if !FileManager.default.fileExists(atPath: videosDirectory.path) {
            
            do {
                print("creating videos directory")
                try FileManager.default.createDirectory(atPath: videosDirectory.path, withIntermediateDirectories: true, attributes: nil)
                return videosDirectory
            }
            catch let error {
                print("\nunable to create video directory: \(error)")
                return nil
            }
        }
        
        return videosDirectory
    }
}
