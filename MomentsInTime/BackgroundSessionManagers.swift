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
    class var shared: BackgroundUploadSessionManager {
        struct Static {
            static let instance = BackgroundUploadSessionManager()
        }
        
        return Static.instance
    }
    
    init()
    {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.background")
        configuration.timeoutIntervalForRequest = 3600
        configuration.timeoutIntervalForResource = 3600 //1 hour - default is 7 days
        super.init(configuration: configuration)
        
        self.configureTaskDidFinishHandler()
        self.configureSessionDidFinishHandler()
    }
    
    var uploadCompletion: UploadCompletion?
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
    
    /**
     * We cannot rely on completion/ response handlers to chain the necessary upload flow requests since we are background compatable.
     * We can only rely on the session delegate callbacks/ closures, and we can just pass along the upload completion handler
     * until the very end of the process, then call it...
     */
    func upload(moment: Moment, router: URLRequestConvertible, uploadCompletion: @escaping UploadCompletion)
    {
        self.moment = moment
        self.uploadCompletion = uploadCompletion
        
        guard let uploadURL = moment.video?.localPlaybackURL else {
            let error = NSError(domain: "BackgroundUploadManager.upload:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't create valid video file url"])
            uploadCompletion(nil, error)
            return
        }
        
        self.upload(uploadURL, with: router)
    }
    
    private func configureTaskDidFinishHandler()
    {
        self.delegate.taskDidComplete = { session, task, error in
            
            guard let moment = self.moment, error == nil else {
                print(error!)
                self.uploadCompletion?(nil, error)
                return
            }
            
            //complete the upload:
            BackgroundUploadCompleteSessionManager.shared.completeUpload(moment: moment, completion: self.uploadCompletion)
        }
    }
    
    private func configureSessionDidFinishHandler()
    {
        self.delegate.sessionDidFinishEventsForBackgroundURLSession = { session in
            DispatchQueue.main.async {
                self.moment = nil
                self.systemCompletionHandler?()
                self.systemCompletionHandler = nil
            }
        }
    }
}

class BackgroundUploadCompleteSessionManager: Alamofire.SessionManager
{
    private static var userDefaults = UserDefaults(suiteName: USER_DEFAULT_SUITE_COMPLETE_UPLOAD)! // do not modify name
    
    class var shared: BackgroundUploadCompleteSessionManager {
        struct Static {
            static let instance = BackgroundUploadCompleteSessionManager()
        }
        
        return Static.instance
    }
    
    init()
    {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.backgroundcomplete")
        configuration.timeoutIntervalForRequest = 3600
        configuration.timeoutIntervalForResource = 3600 //1 hour - default is 7 days
        super.init(configuration: configuration)
        
        self.configureDownloadTaskDidFinishHandler()
        self.configureTaskDidFinishHandler()
        self.configureSessionDidFinishHandler()
    }
    
    var completeURI: String?
    
    var uploadCompletion: UploadCompletion?
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
    
    /**
     * Since completing the upload is part of the background compatable upload flow, we need to use a download task.
     * This works great b/c the response will be saved temporarily to disk, we can inspect/ grab the location header,
     * and add the video metadata, completing the upload flow...
     */
    func completeUpload(moment: Moment, completion: UploadCompletion?)
    {
        self.moment = moment
        self.uploadCompletion = completion
        
        guard let completeURI = self.completeURI else {
            let error = NSError(domain: "BackgroundUploadCompleteManager.completeUpload:", code: 400, userInfo: [NSLocalizedDescriptionKey: "No valid completeURI"])
            self.uploadCompletion?(nil, error)
            return
        }
        
        self.download(UploadRouter.complete(completeURI: completeURI))
    }
    
    private func configureDownloadTaskDidFinishHandler()
    {
        self.delegate.downloadTaskDidFinishDownloadingToURL = { session, task, url in
            
            guard let httpResponse = task.response as? HTTPURLResponse,
                let locationURI = httpResponse.allHeaderFields["Location"] as? String else {
                let error = NSError(domain: "BackgroundUploadCompleteManager.downloadFinish:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Could not get location header"])
                self.uploadCompletion?(nil, error)
                return
            }
            
            //update moment with the uri:
            DispatchQueue.main.async {
                Moment.writeToRealm {
                    self.moment?.video?.uri = locationURI
                }
            }
        }
    }
    
    private func configureTaskDidFinishHandler()
    {
        self.delegate.taskDidComplete = { session, task, error in
            
            guard let moment = self.moment, error == nil else {
                print(error!)
                self.uploadCompletion?(nil, error)
                return
            }
            
            //add video metadata:
            BackgroundUploadVideoMetadataSessionManager.shared.sendMetadata(moment: moment, completion: self.uploadCompletion)
        }
    }
    
    private func configureSessionDidFinishHandler()
    {
        self.delegate.sessionDidFinishEventsForBackgroundURLSession = { session in
            DispatchQueue.main.async {
                self.moment = nil
                self.systemCompletionHandler?()
                self.systemCompletionHandler = nil
            }
        }
    }
}

//let this guy hold onto the completion for the UI
class BackgroundUploadVideoMetadataSessionManager: Alamofire.SessionManager
{
    private static var userDefaults = UserDefaults(suiteName: USER_DEFAULT_SUITE_UPLOAD_METADATA)! // do not modify name
    
    class var shared: BackgroundUploadVideoMetadataSessionManager {
        struct Static {
            static let instance = BackgroundUploadVideoMetadataSessionManager()
        }
        
        return Static.instance
    }
    
    init()
    {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.backgroundMetadata")
        configuration.timeoutIntervalForRequest = 3600
        configuration.timeoutIntervalForResource = 3600 //1 hour - default is 7 days
        super.init(configuration: configuration)
        
        self.configureTaskDidFinishHandler()
        self.configureSessionDidFinishHandler()
    }
    
    var uploadCompletion: UploadCompletion?
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
    
    /**
     * again we will use a download task for this request so we can remain background compatable.
     * we can inspect/ parse the JSON newly uploaded Video object response in downloadTaskDidFinishDownloadingToURL:
     */
    func sendMetadata(moment: Moment, completion: UploadCompletion?)
    {
        self.moment = moment
        self.uploadCompletion = completion
        
        guard let video = self.moment?.video else {
            let error = NSError(domain: "BackgroundUploadVideoMetadataSessionManager.sendMetadata:", code: 400, userInfo: [NSLocalizedDescriptionKey: "No valid video"])
            self.uploadCompletion?(nil, error)
            return
        }
        
        self.download(VideoRouter.update(video))
    }
    
    private func configureTaskDidFinishHandler()
    {
        self.delegate.taskDidComplete = { session, task, error in
            
            guard let moment = self.moment, error == nil else {
                print(error!)
                self.uploadCompletion?(nil, error)
                return
            }
            
            self.uploadCompletion?(moment, nil)
        }
    }
    
    private func configureSessionDidFinishHandler()
    {
        self.delegate.sessionDidFinishEventsForBackgroundURLSession = { session in
            DispatchQueue.main.async {
                self.moment = nil
                self.systemCompletionHandler?()
                self.systemCompletionHandler = nil
            }
        }
    }
}

