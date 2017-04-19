//
//  Note.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/19/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

class Note: NSObject
{
    var text: String?
    
    init(withText text: String)
    {
        super.init()
        self.text = text
    }
    
    override init()
    {
        self.text = nil
    }
}
