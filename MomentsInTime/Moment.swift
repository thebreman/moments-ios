//
//  Moment.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import RealmSwift

enum MomentStatus: Int
{
    case new
    case local
    case uploading
    case uploadFailed
    case processing
    case live
}

class Moment: Object
{
    dynamic var momentID = UUID().uuidString
    dynamic var subject: Subject?
    dynamic var video: Video?
    dynamic var createdAt = Date()
    dynamic var existsInRealm = false
    dynamic var _momentStatus = MomentStatus.new.rawValue
    
    let notes = List<Note>()
    
    var momentStatus: MomentStatus {
        get {
            return MomentStatus(rawValue: self._momentStatus)!
        }
        set {
            Moment.writeToRealm {
                self._momentStatus = newValue.rawValue
            }
        }
    }
    
    var isReadyToSubmit: Bool {
        guard self.momentStatus != .uploading || self.momentStatus != .processing || self.momentStatus != .live else {
            return false
        }
        let readyToSubmit = self.subject?.name != nil
            && self.video?.name != nil
            && self.video?.videoDescription != nil
            && self.video?.localURL != nil
        return readyToSubmit
    }
    
    override static func primaryKey() -> String?
    {
        return "momentID"
    }
    
    override static func ignoredProperties() -> [String]
    {
        return ["momentStatus"]
    }
    
    //if successful, the newly created video URI will be passed along in completion:
    func upload(completion: @escaping StringCompletionHandler)
    {
        if let video = self.video {
            VimeoConnector().create(video: video, uploadProgress: { fractionCompleted in
                
                //update progress UI
                
            }, completion: { videoURI, error in
                
                //handle completion
                
            })
        }
    }
    
    // add a new moment to realm:
    func create()
    {
        if !self.existsInRealm {
            
            //add moment to realm:
            if let realm = try? Realm() {
                
                try? realm.write {
                    realm.add(self)
                    self.existsInRealm = true
                }
            }
        }
    }
    
    func deleteLocally()
    {
        if self.existsInRealm {
            
            print("deleting moment in realm")
            self.subject?.deleteLocally()
            self.video?.deleteLocally()
            
            //delete moment from realm:
            if let realm = try? Realm() {
                
                try? realm.write {
                    
                    if let subject = self.subject {
                        realm.delete(subject)
                    }
                    
                    if let video = self.video {
                        realm.delete(video)
                    }
                    
                    realm.delete(notes)
                    realm.delete(self)
                }
            }
        }
    }
}

extension Moment
{
    //modify objects and perform any UI updates in handler:
    class func writeToRealm(withHandler handler: () -> Void)
    {
        if let realm = try? Realm() {
            realm.beginWrite()
            handler()
            try? realm.commitWrite()
        }
    }
}
