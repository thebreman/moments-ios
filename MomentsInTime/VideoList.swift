//
//  VideoList.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/31/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

class VideoList
{
    lazy var videos = [Video]()
    
    func fetchCommunityVideos(completion: @escaping (Error?) -> Void)
    {
        APIService().getVideosForCommunity { (videos, error) in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            if let fetchedVideos = videos {
                DispatchQueue.main.async {
                    self.videos = fetchedVideos
                    completion(nil)
                }
            }
        }
    }
}
