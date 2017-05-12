//
//  TopicHeaderSection.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/11/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

let COPY_CHOOSE_TOPIC = "Choose a topic or make your own"
let COPY_LINK_MAKE_YOUR_OWN = "make your own"

struct TopicSectionHeader
{
    static var text: String {
        return COPY_CHOOSE_TOPIC
    }
    
    static var activeLinks: [String] {
        return [COPY_LINK_MAKE_YOUR_OWN]
    }
}
