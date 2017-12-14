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
    @objc dynamic var subjectID = UUID().uuidString
    @objc dynamic var name: String? = nil
    @objc dynamic var role: String? = nil
    @objc dynamic var profileImageURL: String? = nil
    
    private var _profileImage: UIImage?
    
    var profileImage: UIImage? {
        get {
            if self._profileImage == nil {
                if let localURLString = self.profileImageURL {
                    self._profileImage = Assistant.loadImageFromDisk(withRelativeUrlString: localURLString)
                    return self._profileImage
                }
            }
            return self._profileImage
        }
        set {
            self._profileImage = newValue
        }
    }
    
    var isValid: Bool {
        return self.name != nil
    }
    
    func deleteLocally()
    {
        if let localImageURLString = self.profileImageURL {
            print("deleting profileImage")
            Assistant.removeImageFromDisk(atRelativeURLString: localImageURLString)
        }
    }
    
    override static func primaryKey() -> String?
    {
        return "subjectID"
    }
    
    override static func ignoredProperties() -> [String]
    {
        return ["profileImage", "_profileImage"]
    }
}
