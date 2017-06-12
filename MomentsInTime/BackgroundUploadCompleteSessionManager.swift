//
//  BackgroundUploadCompleteSessionManager.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/14/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import Alamofire
import RealmSwift

/***** DO NOT CHANGE *****/
private let USER_DEFAULT_SUITE_COMPLETE_UPLOAD = "CurrentUserUploadComplete"
private let DEFAULTS_KEY_MOMENT_UPLOAD_COMPLETE = "momentIDKey"
private let DEFAULTS_KEY_COMPLETE_URI = "uploadCompleteURI"
/***** DO NOT CHANGE *****/

class BackgroundUploadCompleteSessionManager: Alamofire.SessionManager
{
    private static var userDefaults = UserDefaults(suiteName: USER_DEFAULT_SUITE_COMPLETE_UPLOAD)! // do not modify name
    
    var uploadCompletion: UploadCompletion?
    var systemCompletionHandler: (() -> Void)?
    
    var completeURI: String? {
        get {
            return BackgroundUploadCompleteSessionManager.userDefaults.string(forKey: DEFAULTS_KEY_COMPLETE_URI)
        }
        set {
            if newValue == nil {
                BackgroundUploadCompleteSessionManager.userDefaults.removeObject(forKey: DEFAULTS_KEY_COMPLETE_URI)
            }
            else {
                BackgroundUploadCompleteSessionManager.userDefaults.set(newValue!, forKey: DEFAULTS_KEY_COMPLETE_URI)
            }
        }
    }
    
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
            DispatchQueue.main.async {
                let error = NSError(domain: "BackgroundUploadCompleteManager.completeUpload:", code: 400, userInfo: [NSLocalizedDescriptionKey: "No valid completeURI"])
                self.moment?.handleFailedUpload()
                self.moment = nil
                self.uploadCompletion?(nil, error)
            }

            return
        }
        
        self.download(UploadRouter.complete(completeURI: completeURI))
    }
    
    private func configureDownloadTaskDidFinishHandler()
    {
        self.delegate.downloadTaskDidFinishDownloadingToURL = { (session, task, url) in
            DispatchQueue.main.async {
                
                guard let httpResponse = task.response as? HTTPURLResponse,
                    let locationURI = httpResponse.allHeaderFields["Location"] as? String,
                    let moment = self.moment else {
                        let error = NSError(domain: "BackgroundUploadCompleteManager.downloadFinish:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Could not get location header"])
                        self.moment?.handleFailedUpload()
                        self.uploadCompletion?(nil, error)
                        self.moment = nil
                        return
                }
                
                //update moment with the uri:
                Moment.writeToRealm {
                    self.moment?.video?.uri = locationURI
                }
                
                //add video metadata and move video to Upload Album:
                BackgroundUploadVideoMetadataSessionManager.shared.sendMetadata(moment: moment, completion: self.uploadCompletion)
                BackgroundUploadAlbumSessionManager.shared.addToUploadAlbum(moment: moment, completion: nil)
                self.completeURI = nil
                self.moment = nil
            }
        }
    }
    
    private func configureTaskDidFinishHandler()
    {
        //handle errors here
        self.delegate.taskDidComplete = { (session, task, error) in
            DispatchQueue.main.async {
                
                guard let response = task.response as? HTTPURLResponse,
                    response.statusCode >= 200,
                    response.statusCode < 300,
                    error == nil else {
                    print(error ?? "")
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
                self.completeURI = nil
                self.moment = nil
                self.systemCompletionHandler?()
                self.systemCompletionHandler = nil
            }
        }
    }
}
