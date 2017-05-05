//
//  MomentList.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import RealmSwift

class MomentList: NSObject
{
    var moments = [Moment]()
    
    private(set) var savedMoments : Results<Moment>?
    
    var momentVideos: [Video] {
        
        if let myMoments = self.moments {
            return myMoments.flatMap { $0.video }
        }
        
        return [Video]()
    }
    
    override init()
    {
        super.init()
        self.savedMoments = self.getMoments()
    }
    
    private func getMoments() -> Results<Moment>?
    {
        if let realm = try? Realm() {
            self.savedMoments = realm.objects(Moment.self)
            return self.savedMoments?.sorted(by: [SortDescriptor(keyPath: "createdAt", ascending: false)])
            self.moments = self.savedMoments.
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
