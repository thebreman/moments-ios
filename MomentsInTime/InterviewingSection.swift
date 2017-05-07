//
//  InterviewingSection.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/4/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

private let COPY_TEXT_PLACEHOLDER_NAME_FIELD = "Enter name"
private let COPY_TEXT_PLACEHOLDER_ROLE_FIELD = "Enter role"
private let COPY_TITLE_BUTTON_SELECT_PICTURE = "Select photo (optional)"

enum InterviewingSection: Int
{
    case picture = 0
    case name = 1
    case role = 2
    
    static var titles: [String] {
        return ["Picture (optional)", "Name", "Role"]
    }
    
    //for name and role return textField placeholder text
    //for picture return activeLabel text
    var cellContentText: String {
        switch self {
        case .picture: return COPY_TITLE_BUTTON_SELECT_PICTURE
        case .name: return COPY_TEXT_PLACEHOLDER_NAME_FIELD
        case .role: return COPY_TEXT_PLACEHOLDER_ROLE_FIELD
        }
    }
}
