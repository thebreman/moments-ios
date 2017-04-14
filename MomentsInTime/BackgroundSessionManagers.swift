//
//  BackgroundSessionManagers.swift
//  VideoWonderland
//
//  Created by Andrew Ferrarone on 4/12/17.
//  Copyright © 2017 Andrew Ferrarone. All rights reserved.
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
        let sessionManager = BackgroundUploadSessionManager(configuration: configuration)
        return sessionManager
    }()
    
    var systemCompletionHandler: (() -> Void)?
}

class BackgroundUploadCompleteSessionManager: Alamofire.SessionManager
{
    static let shared: BackgroundUploadCompleteSessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.backgroundcomplete")
        let sessionManager = BackgroundUploadCompleteSessionManager(configuration: configuration)
        return sessionManager
    }()
    
    var systemCompletionHandler: (() -> Void)?

    var completeURI: String?
}

class BackgroundUploadVideoMetadataSessionManager: Alamofire.SessionManager
{
    static let shared: BackgroundUploadVideoMetadataSessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.backgroundMetadata")
        let sessionManager = BackgroundUploadVideoMetadataSessionManager(configuration: configuration)
        return sessionManager
    }()
    
    var systemCompletionHandler: (() -> Void)?
}

