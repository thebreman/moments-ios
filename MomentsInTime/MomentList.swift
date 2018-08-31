//
//  MomentList.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import RealmSwift

private let ID_ALBUM_COMMUNITY = "4626849"

typealias MomentListCompletion = (MomentList?, Error?) -> Void
typealias MomentListNewMomentsCompletion = (MomentList?, [Moment]?, Error?) -> Void

class MomentList: NSObject
{
    var moments = [Moment]()
    
    // For paging videos w/ VimeoConnector
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
            self.moments = savedMoments.compactMap { $0 }
        }
        
        return self.moments
    }
    
    // searches for videos of the specified username:
    func fetchCommunityMoments(forUsername name: String, completion: @escaping MomentListCompletion)
    {
        VimeoConnector().getCommunityMoments(forUserName: name) { (momentList, error) in
            self.handleMomentListResponse(forFetchedList: momentList, error: error, completion: completion)
        }
    }
    
    // fetches initial videos:
    func fetchCommunityMoments(completion: MomentListCompletion?)
    {
        VimeoConnector().getCommunityMoments { (momentList, error) in
            self.handleMomentListResponse(forFetchedList: momentList, error: error, completion: completion)
        }
    }
    
    // fetches next page of videos if necessary:
    func fetchNextCommunityMoments(completion: MomentListNewMomentsCompletion?)
    {
        guard let nextPage = self.nextPagePath else {
            let error = NSError(domain: "MomentList", code: 400, userInfo: [NSLocalizedDescriptionKey: "no next page to fetch"])
            completion?(self, nil, error)
            return
        }
        
        VimeoConnector().getNextPageOfVideos(forPagePath: nextPage) { (momentList, error) in
            
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
    
    private func handleMomentListResponse(forFetchedList momentList: MomentList?, error: Error?, completion: MomentListCompletion?)
    {
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
    
    private func getSavedMoments() -> Results<Moment>?
    {
        if let realm = try? Realm() {
            let savedMoments = realm.objects(Moment.self)
            return savedMoments.sorted(by: [SortDescriptor(keyPath: "createdAt", ascending: false)])
        }
        
        return nil
    }
}
