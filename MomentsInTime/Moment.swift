//
//  Moment.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import RealmSwift

class Moment: Object
{
    dynamic var momentID = UUID().uuidString
    dynamic var subject: Subject?
    dynamic var video: Video?
    let notes = List<Note>()
    
    var isValid: Bool {
        return false
    }
    
    override static func primaryKey() -> String?
    {
        return "momentID"
    }
}
