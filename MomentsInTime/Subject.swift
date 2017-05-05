//
//  Subject.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class Subject: Object
{
    dynamic var subjectID = UUID().uuidString
    dynamic var name: String? = nil
    dynamic var role: String? = nil
    dynamic var profileImageURL: String? = nil
    
    var profileImage: UIImage?
    
    var isValid: Bool {
        return self.name != nil
    }
    
    override static func primaryKey() -> String?
    {
        return "subjectID"
    }
    
    override static func ignoredProperties() -> [String]
    {
        return ["profileImage"]
    }
}
