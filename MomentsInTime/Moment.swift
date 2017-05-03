//
//  Moment.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

class Moment: NSObject
{
    var subject: Subject?
    var video: Video?
    var notes = [Note]()
    
    var isValid: Bool {
        return false
    }
    
    func validate() //?
    {
        //TODO
    }
}
