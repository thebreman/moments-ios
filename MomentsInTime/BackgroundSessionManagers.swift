//
//  BackgroundSessionManagers.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Alamofire

/**
 * Create a session manager with background configuration.
 * Only create a background session with a given identifier once.
 * For multiple sessions they each need their own identifier...
 */

class BackgroundUploadSessionManager: Alamofire.SessionManager
{
    //guaranteed to be lazily initialized only once, even when accessed across multiple threads simultaneously:
    static let shared: BackgroundUploadSessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.background")
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10 //1 hour - default is 7 days
        let sessionManager = BackgroundUploadSessionManager(configuration: configuration)
        return sessionManager
    }()
    
    var systemCompletionHandler: (() -> Void)?
    var moment: Moment?
}

class BackgroundUploadCompleteSessionManager: Alamofire.SessionManager
{
    static let shared: BackgroundUploadCompleteSessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.backgroundcomplete")
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10 //1 hour - default is 7 days
        let sessionManager = BackgroundUploadCompleteSessionManager(configuration: configuration)
        return sessionManager
    }()
    
    var systemCompletionHandler: (() -> Void)?
    var moment: Moment?
    var completeURI: String?
}

class BackgroundUploadVideoMetadataSessionManager: Alamofire.SessionManager
{
    static let shared: BackgroundUploadVideoMetadataSessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.backgroundMetadata")
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10 //1 hour - default is 7 days
        let sessionManager = BackgroundUploadVideoMetadataSessionManager(configuration: configuration)
        return sessionManager
    }()
    
    var systemCompletionHandler: (() -> Void)?
    var moment: Moment?
}

