//
//  Video.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class Video: Object
{
    //these will be persisted with Realm for user's MyMoments 
    //everything else will come from Vimeo JSON objects
    dynamic var videoID = UUID().uuidString
    dynamic var uri: String? = nil
    dynamic var name: String? = nil
    dynamic var videoDescription: String? = nil
    dynamic var localURL: String? = nil //file path for videos that are being uploaded:
    dynamic var localThumbnailImageURL: String? = nil
    dynamic var videoLink: String?
    dynamic var isLocal: Bool = false
    dynamic var liveVerified: Bool = false
    dynamic var playbackURL: String?
    
    var thumbnailImageURL: String?
    var status: String?
    
    private var _localThumbnailImage: UIImage?
    
    var localThumbnailImage: UIImage? {
        get {
            if self._localThumbnailImage == nil {
                if let localURLString = self.localThumbnailImageURL {
                    self._localThumbnailImage = Assistant.loadImageFromDisk(withRelativeUrlString: localURLString)
                    return self._localThumbnailImage
                }
            }
            return self._localThumbnailImage
        }
        set {
            self._localThumbnailImage = newValue
        }
    }
    
    var isPlayable: Bool {
        return self.localURL != nil || self.uri != nil
    }
    
    var localPlaybackURL: URL? {
        guard let localURLString = self.localURL, let videos = FileManager.getVideosDirectory() else { return nil }
        let path = videos.appendingPathComponent(localURLString)
        if FileManager.default.fileExists(atPath: path.path) {
            return path
        }
        return nil
    }
    
    /**
     * if we have previously fetched and stored a playbackURL, completion will contain this url,
     * if not, fetch and store the url and pass this along in the completion handler:
     */
    func fetchPlaybackURL(completion: @escaping StringCompletionHandler)
    {
        if let url = self.playbackURL {
            completion(url, nil)
            return
        }
        
        VimeoConnector().getPlaybackURL(forVideo: self) { (urlString, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            if let newURLString = urlString {
                
                //delete local video if we have one:
                if let localVideoURLString = self.localURL {
                    print("removing local video since we have a playback url")
                    Assistant.removeVideoFromDisk(atRelativeURLString: localVideoURLString) { success in
                        if success {
                            Moment.writeToRealm {
                                self.localURL = nil
                            }
                        }
                    }
                }
                
                //update with new playbackURL:
                Moment.writeToRealm {
                    self.playbackURL = newURLString
                }
                completion(newURLString, nil)
                return
            }
                        
            let error = NSError(domain: "Video", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't fetch valid playbackURL"])
            completion(nil, error)
        }
    }
    
    func deleteLocally()
    {
        if let localImageURLString = self.localThumbnailImageURL {
            print("Deleting video local thumbnail image")
            Assistant.removeImageFromDisk(atRelativeURLString: localImageURLString)
        }
        
        if let localVideoURLString = self.localURL {
            print("Deleting video local video")
            Assistant.removeVideoFromDisk(atRelativeURLString: localVideoURLString, completion: nil)
        }
    }
    
    /**
     * Video must have the following properties to be valid,
     * ok if there is no description:
     */
    func isValid() -> Bool
    {
        let valid = (self.uri != nil
            && self.name != nil
            && self.name != "untitled"
            && self.name != "Untitled"
            && self.thumbnailImageURL != nil
        )
        
        //check the status of the video: it could be currently uploading, or processing, etc.
        var available = false
        if let videoStatus = self.status {
            available = videoStatus == "available"
        }
        
        //only validate videos that are valid and available
        return valid && available
    }
    
    override static func primaryKey() -> String?
    {
        return "videoID"
    }
    
    override static func ignoredProperties() -> [String]
    {
        return ["thumbnailImageURL", "status", "localThumbnailImage", "_localThumbnailImage"]
    }
}

extension Video: VideoRouterCompliant
{
    /**
     * For uploading new videos/ adding metadata, we will let vimeo choose thumbnail image,
     * all we need to return here is name and description:
     */
    func videoParameters() -> [String : Any]
    {
        var params = [String: Any]()
        
        if let name = self.name {
            params["name"] = name
        }
        
        if let description = self.videoDescription {
            params["description"] = description
        }
        
        return params
    }
    
    class func from(parameters params: [String: Any]) -> Video?
    {
        let video = Video()
        
        let uri = params["uri"] as? String
        let name = params["name"] as? String
        let videoDescription = params["description"] as? String
        let videoStatus = params["status"] as? String
        let videoLink = params["link"] as? String
        
        //grab pictures object for video thumbnailImageURL:
        var thumbnailImageURL: String?
        
        if let pictures = params["pictures"] as? [String: Any] {
            thumbnailImageURL = Video.imageURL(fromPictures: pictures)
        }
    
        video.uri = uri
        video.name = name
        video.videoDescription = videoDescription
        video.thumbnailImageURL = thumbnailImageURL
        video.status = videoStatus
        video.videoLink = videoLink
        
        if video.isValid() {
            return video
        }
        else {
            print("Video is Invalid")
            return nil
        }
    }
    
    class func imageURL(fromPictures pictures: [String: Any]) -> String?
    {
        var imageURL: String?
        
        if let pictureSizes = pictures["sizes"] as? [[String: Any]] {
            
            var chosenPictureObject: [String: Any]?
            
            //for videoThumbnail images, try and choose second to last pictureSizeObject (960x540)
            //otherwise there must just be one picture so grab that one:
            if pictureSizes.count > 1 {
                chosenPictureObject = pictureSizes[pictureSizes.count - 2]
            }
            else {
                chosenPictureObject = pictureSizes.last
            }
            
            imageURL = chosenPictureObject?["link"] as? String
        }
        
        return imageURL
    }
}
