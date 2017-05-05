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
    var moments: Results<Moment>?
    
    var momentVideos: [Video] {
        
        if let myMoments = self.moments {
            return myMoments.flatMap { $0.video }
        }
        
        return [Video]()
    }
    
    override init()
    {
        super.init()
        self.moments = self.getMoments()
    }
    
    private func getMoments() -> Results<Moment>?
    {
        if let realm = try? Realm() {
            self.moments = realm.objects(Moment.self)
            return self.moments?.sorted(by: [SortDescriptor(keyPath: "createdAt", ascending: false)])
        }
        
        return nil
    }
}
