//
//  NewMomentSetting.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/18/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

let COPY_SELECT_INTERVIEW_SUBJECT = "Select a special person to interview"
let COPY_CREATE_TOPIC = "Select a topic"
let COPY_CREATE_VIDEO = "Start filming or upload a video"
let COPY_CREATE_NOTE = "Add a new note"

let COPY_LINK_START_FILMING = "Start filming"
let COPY_LINK_UPLOAD_VIDEO = "upload a video"

enum NewMomentSetting: Int
{
    case interviewing = 0
    case topic = 1
    case video = 2
    case notes = 3
    
    static var titles: [String] {
        return ["Interviewing", "Topic", "Video", "Notes"]
    }
    
    static var defaultNotes: [Note] {
        
        let notes = [
            Note(withText: "Add or remove as many notes as you'd like."),
            Note(withText: "Videos are generally 2-3 minutes long and themed around a question or topic in interview format. Feel free to interview anyone you know- including yourself!"),
            Note(withText: "To make the most of your interview, prepare your questions in advance, outline the conversation before recording, and avoid yes or no answers."),
            Note(withText: "Be spontaneous, but please be the kind and courteous person you’re known for being. People of all ages can access this content. 🙂"),
            ]
        
        return notes
    }
    
    var text: String {
        switch self {
        case .interviewing: return COPY_SELECT_INTERVIEW_SUBJECT
        case .topic: return COPY_CREATE_TOPIC
        case .video: return COPY_CREATE_VIDEO
        case .notes: return COPY_CREATE_NOTE
        }
    }
    
    var activeLinks: [String] {
        switch self {
        case .interviewing: return [COPY_SELECT_INTERVIEW_SUBJECT]
        case .topic: return [COPY_CREATE_TOPIC]
        case .video: return [COPY_LINK_START_FILMING, COPY_LINK_UPLOAD_VIDEO]
        case .notes: return [COPY_CREATE_NOTE]
        }
    }
}
