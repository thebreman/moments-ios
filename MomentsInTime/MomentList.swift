//
//  MomentList.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import RealmSwift

typealias MomentListCompletion = (MomentList?, Error?) -> Void
typealias MomentListNewMomentsCompletion = (MomentList?, [Moment]?, Error?) -> Void

class MomentList: NSObject
{
    var moments = [Moment]()
    
    private static let firstPagePath: String = "/me/videos"
    private(set) var nextPagePath: String?
    
    //use this in a a getter for localMoments:
    private(set) var savedMoments : Results<Moment>?
    var momentVideos: [Video] {
        
        if let myMoments = self.savedMoments {
            return myMoments.flatMap { $0.video }
        }
        
        return [Video]()
    }
    
    ////////////////////////**********************************/////////////////////////////////********
    
    override init()
    {
        super.init()
        //self.savedMoments = self.getLocalMoments()
    }
    
    init(moments: [Moment], nextPagePath: String?)
    {
        super.init()
        self.moments = moments
        self.nextPagePath = nextPagePath
    }
    
    var hasNextPage: Bool {
        return self.nextPagePath != nil
    }
    
    func fetchCommunityMoments(completion: MomentListCompletion?)
    {
        VimeoConnector().getCommunityMoments(forPagePath: MomentList.firstPagePath) { (momentList, error) in
            
            guard error == nil else {
                completion?(nil, error)
                return
            }
            
            if let fetchedMomentList = momentList {
                
                DispatchQueue.main.async {
                    self.moments = fetchedMomentList.moments
                    self.nextPagePath = fetchedMomentList.nextPagePath
                    completion?(self, nil)
                }
            }
        }
    }
    
    func fetchNextCommunityMoments(completion: MomentListNewMomentsCompletion?)
    {
        guard let nextPage = self.nextPagePath else { return }
        
        VimeoConnector().getCommunityMoments(forPagePath: nextPage) { (momentList, error) in
            
            guard error == nil else {
                completion?(nil, nil, error)
                return
            }
            
            if let fetchedMomentList = momentList {
                
                DispatchQueue.main.async {
                    self.moments += fetchedMomentList.moments
                    self.nextPagePath = fetchedMomentList.nextPagePath
                    completion?(self, fetchedMomentList.moments, nil)
                }
            }
        }
    }
    
    //MARK: Utilities
    
    private func getLocalMoments() -> Results<Moment>?
    {
        if let realm = try? Realm() {
            self.savedMoments = realm.objects(Moment.self)
            return self.savedMoments?.sorted(by: [SortDescriptor(keyPath: "createdAt", ascending: false)])
        }
        
        return nil
    }
    
    func addMoment()
    {
        
    }
    
    func removeMoments()
    {
        
    }
}
