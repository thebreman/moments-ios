//
//  DescriptionSection.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/4/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

private let COPY_TEXT_PLACEHOLDER_TITLE_FIELD = "Headline (short and sweet)"
private let COPY_TEXT_PLACEHOLDER_DESCRIPTION_FIELD = "Question/Theme"

enum DescriptionSection: Int
{
    case title = 0
    case description = 1
    
    static var titles: [String] {
        return ["Title", "Description"]
    }
    
    var placeholderText: String {
        switch self {
        case .title: return COPY_TEXT_PLACEHOLDER_TITLE_FIELD
        case .description: return COPY_TEXT_PLACEHOLDER_DESCRIPTION_FIELD
        }
    }
}
