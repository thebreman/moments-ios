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
    
    //for fetching the community list:
    //for search, we will still update nextPagePath, but use a different mechanism for the initial fetch...
    private static let firstPagePath: String = "/me/albums/\(ID_ALBUM_COMMUNITY)/videos"
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
    
    func fetchCommunityMoments(forUsername name: String, completion: @escaping MomentListCompletion)
    {
        VimeoConnector().getCommunityMoments(forUserName: name) { (momentList, error) in
            self.handleMomentListResponse(forFetchedList: momentList, error: error, completion: completion)
        }
    }
    
    func fetchCommunityMoments(completion: MomentListCompletion?)
    {
        VimeoConnector().getCommunityMoments(forPagePath: MomentList.firstPagePath) { (momentList, error) in
            self.handleMomentListResponse(forFetchedList: momentList, error: error, completion: completion)
        }
    }
    
    func fetchNextCommunityMoments(completion: MomentListNewMomentsCompletion?)
    {
        guard let nextPage = self.nextPagePath else {
            let error = NSError(domain: "MomentList", code: 400, userInfo: [NSLocalizedDescriptionKey: "no next page to fetch"])
            completion?(self, nil, error)
            return
        }
        
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
