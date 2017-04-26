//
//  MITEmptyStateView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/15/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let COPY_TITLE_ASK_TO_INTERVIEW = "Make a Moment"
private let COPY_MESSAGE_ASK_TO_INTERVIEW = "Who do you know that has a story to tell?"
private let COPY_TITLE_BUTTON_ASK_TO_INTERVIEW = "Ask To Interview"

private let COPY_TITLE_EMPTY_STATE = "Where are all the moments?"
private let COPY_MESSAGE_EMPTY_STATE = "Even if you're not ready to film, you can create the plans for an interview now."
private let COPY_TITLE_BUTTON_EMPTY_STATE = "Let's make a moment"

class MITTextActionView: TextActionView
{
    override func setup()
    {
        super.setup()
        
        self.titleFont = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightSemibold)
        self.titleColor = UIColor.mitText
        
        self.messageFont = UIFont.systemFont(ofSize: 14.0)
        self.messageColor = UIColor.darkGray
        
        self.actionFont = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightSemibold)
        self.setActionColor(UIColor.mitActionblue, forState: .normal)
        
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    class func mitEmptyStateView() -> MITTextActionView
    {
        let view = MITTextActionView()
        view.title = COPY_TITLE_EMPTY_STATE
        view.message = COPY_MESSAGE_EMPTY_STATE
        view.actionButton.setTitle(COPY_TITLE_BUTTON_EMPTY_STATE, for: .normal)
        
        return view
    }
    
    class func mitAskToInterviewView() -> MITTextActionView
    {
        let textActionView = MITTextActionView()
        textActionView.title = COPY_TITLE_ASK_TO_INTERVIEW
        textActionView.message = COPY_MESSAGE_ASK_TO_INTERVIEW
        textActionView.actionButton.setTitle(COPY_TITLE_BUTTON_ASK_TO_INTERVIEW, for: .normal)
        
        return textActionView
    }
}
