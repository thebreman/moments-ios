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
    
    override init()
    {
        super.init()
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
    
    func getLocalMoments() -> [Moment]
    {
        if let savedMoments = self.getSavedMoments() {
            self.moments = savedMoments.flatMap { $0 }
        }
        
        return self.moments
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
    
    private func getSavedMoments() -> Results<Moment>?
    {
        if let realm = try? Realm() {
            let savedMoments = realm.objects(Moment.self)
            return savedMoments.sorted(by: [SortDescriptor(keyPath: "createdAt", ascending: false)])
        }
        
        return nil
    }
}
