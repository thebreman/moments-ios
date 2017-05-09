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
    case processing //? not sure how to handle this case...
    case live
}

typealias MomentCompletion = (Moment?, Error?) -> Void

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
    func upload(completion: @escaping MomentCompletion)
    {
        if let video = self.video {
            self.momentStatus = .uploading
            
            VimeoConnector().create(video: video, uploadProgress: nil, completion: { newVideo, error in
                DispatchQueue.main.async {
                    
                    guard error == nil && video.uri != nil else {
                        self.momentStatus = .uploadFailed
                        self.handleFailedUpload(forVideo: video)
                        completion(nil, error)
                        return
                    }
                    
                    self.momentStatus = .live
                    completion(self, nil)
                }
            })
        }
    }
    
    func handleFailedUpload(forVideo video: Video)
    {
        //for now don't do anything, we already updated our momentStatus
        //but maybe we could check if the uri is there but metadata is not
        //then we could patch the metadata in or delete the video to be safe (maybe complete call failed)...
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
