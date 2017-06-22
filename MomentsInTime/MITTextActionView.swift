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
private let COPY_TITLE_BUTTON_ASK_TO_INTERVIEW = "Let's make a moment"

private let COPY_TITLE_EMPTY_STATE = "Where are all the moments?"
private let COPY_MESSAGE_EMPTY_STATE = "Even if you're not ready to film, you can create the plans for an interview now."
private let COPY_TITLE_BUTTON_EMPTY_STATE = "Let's make a moment"

private let COPY_LET_MESSAGE_COMMUNITY_EMPTY_STATE = "Uh Oh. There are no moments yet."

private let COPY_TITLE_WELCOME = "Welcome to Moments in Time!"
private let COPY_MESSAGE_WELCOME = "Watch stories from the community and get inspired to share your own Moments. Scroll down to start."
private let COPY_TITLE_BUTTON_WELCOME = "Ok, Let's go!"

private let COPY_TITLE_SHARE_LIVE_MOMENT = "You made a Moment!"
private let COPY_MESSAGE_SHARE_LIVE_MOMENT = "Your Moment is live! The Moments In Time moderators will review your post before adding it to the community. In the mean time you can share your awesome creation with the world."
private let COPY_TITLE_BUTTON_SHARE_LIVE_MOMENT = "Share your Moment"

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
    
    class func communityEmptyStateView() -> MITTextActionView
    {
        let view = MITTextActionView()
        view.title = COPY_TITLE_EMPTY_STATE
        view.message = COPY_LET_MESSAGE_COMMUNITY_EMPTY_STATE
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
    
    class func mitWelcomeView() -> MITTextActionView
    {
        let view = MITTextActionView()
        view.title = COPY_TITLE_WELCOME
        view.message = COPY_MESSAGE_WELCOME
        view.actionButton.setTitle(COPY_TITLE_BUTTON_WELCOME, for: .normal)
        
        return view
    }
    
    class func mitShareLiveMomentView() -> MITTextActionView
    {
        let view = MITTextActionView()
        view.title = COPY_TITLE_SHARE_LIVE_MOMENT
        view.message = COPY_MESSAGE_SHARE_LIVE_MOMENT
        view.actionButton.setTitle(COPY_TITLE_BUTTON_SHARE_LIVE_MOMENT, for: .normal)
        
        return view
    }
}
