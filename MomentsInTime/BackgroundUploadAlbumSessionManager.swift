//
//  BackgroundUploadAlbumSessionManager.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 6/11/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Alamofire
import RealmSwift

/***** DO NOT CHANGE *****/
private let USER_DEFAULT_SUITE_UPLOAD_ALBUM = "CurrentUserUploadAlbum"
private let DEFAULTS_KEY_MOMENT_UPLOAD_ALBUM = "momentIDKeyAlbum"
/***** DO NOT CHANGE *****/

class BackgroundUploadAlbumSessionManager: Alamofire.SessionManager
{
    private static var userDefaults = UserDefaults(suiteName: USER_DEFAULT_SUITE_UPLOAD_ALBUM)! // do not modify name
    
    var completionHandler: (() -> Void)?
    var systemCompletionHandler: (() -> Void)?
    
    var moment: Moment? {
        get {
            if let momentPrimaryKey = BackgroundUploadAlbumSessionManager.userDefaults.string(forKey: DEFAULTS_KEY_MOMENT_UPLOAD_ALBUM),
                let realm = try? Realm() {
                return realm.object(ofType: Moment.self, forPrimaryKey: momentPrimaryKey)
            }
            return nil
        }
        set {
            if newValue == nil {
                BackgroundUploadAlbumSessionManager.userDefaults.removeObject(forKey: DEFAULTS_KEY_MOMENT_UPLOAD_ALBUM)
            }
            else {
                BackgroundUploadAlbumSessionManager.userDefaults.set(newValue!.momentID, forKey: DEFAULTS_KEY_MOMENT_UPLOAD_ALBUM)
            }
        }
    }
    
    class var shared: BackgroundUploadAlbumSessionManager {
        struct Static {
            static let instance = BackgroundUploadAlbumSessionManager()
        }
        
        return Static.instance
    }
    
    init()
    {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.momentsintime.app.backgroundAlbum")
        configuration.timeoutIntervalForRequest = 3600
        configuration.timeoutIntervalForResource = 3600 //1 hour - default is 7 days
        super.init(configuration: configuration)
        
        self.configureTaskDidFinishHandler()
    }
    
    //again we will use a download task for this request so we can remain background compatable
    func addToUploadAlbum(moment: Moment, completion: (() -> Void)?)
    {
        self.moment = moment
        self.completionHandler = completion
        
        guard let video = self.moment?.video, video.uri != nil else {
            DispatchQueue.main.async {
                Moment.writeToRealm {
                    self.moment?.video?.addedToUploadAlbum = false
                }
                self.moment = nil
                self.completionHandler?()
            }
            return
        }
        
        self.download(UploadRouter.addToUploadAlbum(video))
    }
    
    private func configureTaskDidFinishHandler()
    {
        //handle any errors here:
        self.delegate.taskDidComplete = { (session, task, error) in
            DispatchQueue.main.async {
                
                guard let response = task.response as? HTTPURLResponse,
                    response.statusCode >= 200,
                    response.statusCode < 300,
                    error == nil else {
                    print(error ?? "")
                    Moment.writeToRealm {
                        self.moment?.video?.addedToUploadAlbum = false
                    }
                    self.moment = nil
                    self.completionHandler?()
                    return
                }
                
                Moment.writeToRealm {
                    print("\nsuccessful add to upload album")
                    self.moment?.video?.addedToUploadAlbum = true
                }
                
                self.completionHandler?()
                
                //cleanup:
                self.moment = nil
                self.systemCompletionHandler?()
                self.systemCompletionHandler = nil
            }
        }
    }
}
