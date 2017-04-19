//
//  VideoList.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/31/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

typealias VideoListCompletion = (VideoList?, Error?) -> Void

class VideoList
{
    lazy var videos = [Video]()
    
    func fetchCommunityVideos(completion: VideoListCompletion?)
    {
        VimeoConnector().getVideosForCommunity { (videos, error) in
            
            guard error == nil else {
                completion?(nil, error)
                return
            }
            
            if let fetchedVideos = videos {
                DispatchQueue.main.async {
                    self.videos = fetchedVideos
                    completion?(self, nil)
                }
            }
        }
    }
}
