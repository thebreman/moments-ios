//
//  Moment.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import RealmSwift

typealias MomentCompletion = (Moment?, Error?) -> Void

class Moment: Object
{
    dynamic var momentID = UUID().uuidString
    dynamic var subject: Subject?
    dynamic var video: Video?
    dynamic var topic: Topic?
    dynamic var createdAt = Date()
    dynamic var existsInRealm = false
    dynamic var _momentStatus = MomentStatus.new.rawValue
    
    let notes = List<Note>()
    
    var momentStatus: MomentStatus {
        get {
            return MomentStatus(rawValue: self._momentStatus)!
        }
        set {
            self._momentStatus = newValue.rawValue
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
    
    var canonicalTitle : String {
        let name = self.subject?.name ?? "" // assuming these are trimmed
        let separator = name != "" ? " - " : "" // only show the separator when there's something to separate
        let topicTitle = self.topic?.title ?? ""
        
        return "\(name.trimmed())\(separator)\(topicTitle.trimmed())"
    }
    
    override static func primaryKey() -> String?
    {
        return "momentID"
    }
    
    override static func ignoredProperties() -> [String]
    {
        return ["momentStatus", "vimeoConnector"]
    }
    
    private let vimeoConnector = VimeoConnector()
    
    //if successful, the newly created video URI will be passed along in completion:
    func upload(completion: @escaping MomentCompletion)
    {
        //make sure we have a video
        if let video = self.video {
            Moment.writeToRealm {
                self.momentStatus = .uploading
            }
            
            self.vimeoConnector.create(moment: self, uploadProgress: nil) { newVideo, error in
                DispatchQueue.main.async {
                    Moment.writeToRealm {
                        
                        guard error == nil && video.uri != nil else {
                            self.momentStatus = .uploadFailed
                            completion(nil, error)
                            return
                        }
                        
                        self.momentStatus = .live
                        completion(self, nil)
                    }
                }
            }
        }
    }
    
    func handleFailedUpload()
    {
        //for now just update status in case we get called from appDelegate.willTerminate()
        //but maybe we could check if the uri is there but metadata is not
        //then we could patch the metadata in or delete the video to be safe (maybe complete call failed)...
        Moment.writeToRealm {
            self.momentStatus = .uploadFailed
        }
    }
    
    func handleSuccessUpload()
    {
        Moment.writeToRealm {
            self.momentStatus = .live
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
                    self.momentStatus = .local
                    self.existsInRealm = true
                }
            }
        }
    }
    
    func delete()
    {
        //if we can, delete video from Vimeo, then delete locally:
        if let video = self.video, video.uri != nil {
            self.vimeoConnector.delete(video: video) { (success, error) in
                
                //if not successful, return and don't delete locally:
                if success {
                    self.deleteLocally()
                }
                
                return
            }
        }
        else {
            self.deleteLocally()
        }
    }
    
    private func deleteLocally()
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
                    
                    if let topic = self.topic {
                        realm.delete(topic)
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
