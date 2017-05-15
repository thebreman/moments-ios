//
//  BackgroundUploadSessionManager.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/14/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import Alamofire
import RealmSwift

/***** DO NOT CHANGE *****/
private let USER_DEFAULT_SUITE_UPLOAD = "CurrentUserUpload"
private let DEFAULTS_KEY_MOMENT_UPLOAD = "momentIDKey"
/***** DO NOT CHANGE *****/


/**
 * Create a session manager with background configuration.
 * Only create a background session with a given identifier once.
 * For multiple sessions they each need their own identifier...
 */

class BackgroundUploadSessionManager: Alamofire.SessionManager
{
    private static var userDefaults = UserDefaults(suiteName: USER_DEFAULT_SUITE_UPLOAD)! // do not modify name
    
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
            DispatchQueue.main.async {
                let error = NSError(domain: "BackgroundUploadManager.upload:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't create valid video file url"])
                self.moment?.handleFailedUpload()
                uploadCompletion(nil, error)
            }

            return
        }
        
        self.upload(uploadURL, with: router)
    }
    
    private func configureTaskDidFinishHandler()
    {
        self.delegate.taskDidComplete = { session, task, error in
            DispatchQueue.main.async {
                
                guard let moment = self.moment, error == nil else {
                    print(error!)
                    self.moment?.handleFailedUpload()
                    self.uploadCompletion?(nil, error)
                    return
                }
                
                //complete the upload:
                BackgroundUploadCompleteSessionManager.shared.completeUpload(moment: moment, completion: self.uploadCompletion)
                self.moment = nil
                
                Assistant.triggerNotification(withTitle: "uploadComplete", message: "upload task finished", delay: 1)
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
