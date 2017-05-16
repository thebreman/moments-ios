//
//  BackgroundUploadVideoMetadataSessionManager.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/14/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Alamofire
import RealmSwift

/***** DO NOT CHANGE *****/
private let USER_DEFAULT_SUITE_UPLOAD_METADATA = "CurrentUserUploadMetadata"
private let DEFAULTS_KEY_MOMENT_UPLOAD_METADATA = "momentIDKey"
/***** DO NOT CHANGE *****/

//let this guy hold onto the completion for the UI
class BackgroundUploadVideoMetadataSessionManager: Alamofire.SessionManager
{
    private static var userDefaults = UserDefaults(suiteName: USER_DEFAULT_SUITE_UPLOAD_METADATA)! // do not modify name
    
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
        
        self.configureDownloadTaskDidFinishHandler()
        self.configureTaskDidFinishHandler()
        self.configureSessionDidFinishHandler()
    }
    
    /**
     * again we will use a download task for this request so we can remain background compatable.
     * we can inspect/ parse the JSON newly uploaded Video object response in downloadTaskDidFinishDownloadingToURL:
     */
    func sendMetadata(moment: Moment, completion: UploadCompletion?)
    {
        self.moment = moment
        self.uploadCompletion = completion
        
        guard let video = self.moment?.video, video.uri != nil else {
            DispatchQueue.main.async {
                let error = NSError(domain: "BackgroundUploadVideoMetadataSessionManager.sendMetadata:", code: 400, userInfo: [NSLocalizedDescriptionKey: "No valid video"])
                self.moment?.handleFailedUpload()
                self.uploadCompletion?(nil, error)
                self.moment = nil
            }
            
            return
        }
        
        self.download(VideoRouter.update(video))
        
        Assistant.triggerNotification(withTitle: "metatdata send started", message: "PATCH call", delay: 4)
    }
    
    private func configureDownloadTaskDidFinishHandler()
    {
        self.delegate.downloadTaskDidFinishDownloadingToURL = { session, task, url in
            DispatchQueue.main.async {
                
                self.moment?.handleSuccessUpload()
                self.uploadCompletion?(self.moment, nil)
                self.moment = nil
                
                Assistant.triggerNotification(withTitle: "metadata send complete", message: "upload flow finished", delay: 5)
            }
        }
    }
    
    private func configureTaskDidFinishHandler()
    {
        //handle errors here:
        self.delegate.taskDidComplete = { session, task, error in
            DispatchQueue.main.async {
                
                guard error == nil else {
                    print(error!)
                    self.moment?.handleFailedUpload()
                    self.uploadCompletion?(nil, error)
                    self.moment = nil
                    return
                }
            }
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

