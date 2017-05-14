//
//  BackgroundSessionManagers.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Alamofire
import RealmSwift

/***** DO NOT CHANGE *****/
private let USER_DEFAULT_SUITE_UPLOAD = "CurrentUserUpload"
private let USER_DEFAULT_SUITE_COMPLETE_UPLOAD = "CurrentUserUploadComplete"
private let USER_DEFAULT_SUITE_UPLOAD_METADATA = "CurrentUserUploadMetadata"
private let DEFAULTS_KEY_MOMENT_UPLOAD = "momentIDKey"
private let DEFAULTS_KEY_MOMENT_UPLOAD_COMPLETE = "momentIDKey"
private let DEFAULTS_KEY_MOMENT_UPLOAD_METADATA = "momentIDKey"
/***** DO NOT CHANGE *****/

/**
 * Create a session manager with background configuration.
 * Only create a background session with a given identifier once.
 * For multiple sessions they each need their own identifier...
 */

class BackgroundUploadSessionManager: Alamofire.SessionManager
{
    private static var userDefaults = UserDefaults(suiteName: USER_DEFAULT_SUITE_UPLOAD)! // do not modify name
    
    //guaranteed to be lazily initialized only once, even when accessed across multiple threads simultaneously:
    static let shared: BackgroundUploadSessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.background")
        configuration.timeoutIntervalForRequest = 3600
        configuration.timeoutIntervalForResource = 3600 //1 hour - default is 7 days
        let sessionManager = BackgroundUploadSessionManager(configuration: configuration)
        return sessionManager
    }()
    
    var systemCompletionHandler: (() -> Void)?
    
    var moment: Moment? {
        get {
            if let momentPrimaryKey = BackgroundUploadSessionManager.userDefaults.string(forKey: DEFAULTS_KEY_MOMENT_UPLOAD),
                let realm = try? Realm() {
                return realm.object(ofType: Moment.self, forPrimaryKey: momentPrimaryKey)
            }
            return nil
        }
        set {
            if newValue == nil {
                BackgroundUploadSessionManager.userDefaults.removeObject(forKey: DEFAULTS_KEY_MOMENT_UPLOAD)
            }
            else {
                BackgroundUploadSessionManager.userDefaults.set(newValue!.momentID, forKey: DEFAULTS_KEY_MOMENT_UPLOAD)
            }
        }
    }
}

class BackgroundUploadCompleteSessionManager: Alamofire.SessionManager
{
    private static var userDefaults = UserDefaults(suiteName: USER_DEFAULT_SUITE_COMPLETE_UPLOAD)! // do not modify name
    
    static let shared: BackgroundUploadCompleteSessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.backgroundcomplete")
        configuration.timeoutIntervalForRequest = 3600
        configuration.timeoutIntervalForResource = 3600 //1 hour - default is 7 days
        let sessionManager = BackgroundUploadCompleteSessionManager(configuration: configuration)
        return sessionManager
    }()
    
    var completeURI: String?
    
    var systemCompletionHandler: (() -> Void)?
    
    var moment: Moment? {
        get {
            if let momentPrimaryKey = BackgroundUploadCompleteSessionManager.userDefaults.string(forKey: DEFAULTS_KEY_MOMENT_UPLOAD_COMPLETE),
                let realm = try? Realm() {
                return realm.object(ofType: Moment.self, forPrimaryKey: momentPrimaryKey)
            }
            return nil
        }
        set {
            if newValue == nil {
                BackgroundUploadCompleteSessionManager.userDefaults.removeObject(forKey: DEFAULTS_KEY_MOMENT_UPLOAD_COMPLETE)
            }
            else {
                BackgroundUploadCompleteSessionManager.userDefaults.set(newValue!.momentID, forKey: DEFAULTS_KEY_MOMENT_UPLOAD_COMPLETE)
            }
        }
    }
}

class BackgroundUploadVideoMetadataSessionManager: Alamofire.SessionManager
{
    private static var userDefaults = UserDefaults(suiteName: USER_DEFAULT_SUITE_UPLOAD_METADATA)! // do not modify name
    
    static let shared: BackgroundUploadVideoMetadataSessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.backgroundMetadata")
        configuration.timeoutIntervalForRequest = 3600
        configuration.timeoutIntervalForResource = 3600 //1 hour - default is 7 days
        let sessionManager = BackgroundUploadVideoMetadataSessionManager(configuration: configuration)
        return sessionManager
    }()
    
    var systemCompletionHandler: (() -> Void)?
    
    var moment: Moment? {
        get {
            if let momentPrimaryKey = BackgroundUploadVideoMetadataSessionManager.userDefaults.string(forKey: DEFAULTS_KEY_MOMENT_UPLOAD_METADATA),
                let realm = try? Realm() {
                return realm.object(ofType: Moment.self, forPrimaryKey: momentPrimaryKey)
            }
            return nil
        }
        set {
            if newValue == nil {
                BackgroundUploadVideoMetadataSessionManager.userDefaults.removeObject(forKey: DEFAULTS_KEY_MOMENT_UPLOAD_METADATA)
            }
            else {
                BackgroundUploadVideoMetadataSessionManager.userDefaults.set(newValue!.momentID, forKey: DEFAULTS_KEY_MOMENT_UPLOAD_METADATA)
            }
        }
    }
}

