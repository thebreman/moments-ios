//
//  Note.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/19/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import RealmSwift

class Note: Object
{
    dynamic var text: String? = nil
    
    convenience init(withText text: String)
    {
        self.init()
        self.text = text
    }
}
