//
//  Subject.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import UIKit

class Subject: NSObject
{
    var name: String?
    var role: String?
    var profileImageURL: String?
    
    var profileImage: UIImage?
    
    var isValid: Bool {
        return self.name != nil
    }
}
