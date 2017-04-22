//
//  VideoList.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/31/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

typealias VideoListCompletion = (VideoList?, Error?) -> Void
typealias VideoListNewVideosCompletion = (VideoList?, [Video]?, Error?) -> Void

class VideoList
{
    lazy var videos = [Video]()
    
    private(set) var page = 0
    
    private(set) var nextPagePath: String?
    
    func fetchCommunityVideos(completion: VideoListCompletion?)
    {
        VimeoConnector().getVideosForCommunity { (videos, error) in
            
            guard error == nil else {
                completion?(nil, error)
                return
            }
            
            //TODO: set next page path
            
            if let fetchedVideos = videos {
                DispatchQueue.main.async {
                    self.videos = fetchedVideos
                    completion?(self, nil)
                }
            }
        }
    }
    
    func fetchNextCommunityVideos(completion: VideoListNewVideosCompletion?)
    {
        VimeoConnector().getMoreVideoForCommunity { (videos, error) in
            
            guard error == nil else {
                completion?(nil, nil, error)
                return
            }
            
            //TODO: bump page count
            //TODO: set new nextPagePath
            
            if let newVideos = videos {
                DispatchQueue.main.async {
                    self.videos += newVideos
                    completion?(self, newVideos, nil)
                }
            }
        }
    }
}
