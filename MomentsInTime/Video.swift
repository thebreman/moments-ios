//
//  Video.swift
//  APFAVCamera
//
//  Created by Andrew Ferrarone on 3/15/17.
//  Copyright © 2017 Andrew Ferrarone. All rights reserved.
//

import Foundation

class Video: NSObject
{
    var uri: String!
    var name: String!
    var videoDescription: String?
    var videoLinkURL: String!
    var thumbnailImageURL: String!
    var status: String!
    
    //file path for videos that are being uploaded:
    var localURL: String?
    
    //optional url to pass to PlayerViewController (must be fetched upon request):
    private(set) var playbackURL: String?
    
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
                self.playbackURL = newURLString
                completion(newURLString, nil)
                return
            }
                        
            let error = NSError(domain: "Video", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't fetch valid playbackURL"])
            completion(nil, error)
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
            && self.videoLinkURL != nil
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
        let videoLinkURL = params["link"] as? String
        let videoStatus = params["status"] as? String
        
        //grab pictures object for video thumbnailImageURL:
        var thumbnailImageURL: String?
        
        if let pictures = params["pictures"] as? [String: Any] {
            thumbnailImageURL = self.imageURL(fromPictures: pictures)
        }
    
        video.uri = uri
        video.name = name
        video.videoDescription = videoDescription
        video.videoLinkURL = videoLinkURL
        video.thumbnailImageURL = thumbnailImageURL
        video.status = videoStatus
        
        if video.isValid() {
            return video
        }
        else {
            print("Video is Invalid")
            return nil
        }
    }
    
    private static func imageURL(fromPictures pictures: [String: Any]) -> String?
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
