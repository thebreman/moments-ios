//
//  Moment.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import RealmSwift

private let COPY_STATUS_LOCAL = "In Progress"
private let COPY_STATUS_UPLOADING = "Uploading"
private let COPY_STATUS_UPLOAD_FAILED = "Upload Failed! Tap to Retry"
private let COPY_STATUS_LIVE = "Live"

enum MomentStatus: Int
{
    case new
    case local
    case uploading
    case uploadFailed
    case processing //? not sure how to handle this case...
    case live
    
    var message: String? {
        switch self {
        case .local: return COPY_STATUS_LOCAL
        case .uploading: return COPY_STATUS_UPLOADING
        case .uploadFailed: return COPY_STATUS_UPLOAD_FAILED
        case .live: return COPY_STATUS_LIVE
        default: return nil
        }
    }
    
    var color: UIColor? {
        switch self {
        case .local: return UIColor.mitOrange
        case .uploading: return UIColor.mitActionblue
        case .uploadFailed: return UIColor.mitRed
        case .live: return UIColor.mitGreen
        default: return nil
        }
    }
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
    
    private(set) var momentStatus: MomentStatus {
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
            
            self.vimeoConnector.create(moment: self, uploadProgress: nil, completion: { newVideo, error in
                DispatchQueue.main.async {
                    Moment.writeToRealm {
                        
                        guard error == nil && video.uri != nil else {
                            self.momentStatus = .uploadFailed
                            self.handleFailedUpload()
                            completion(nil, error)
                            return
                        }
                        
                        self.momentStatus = .live
                        completion(self, nil)
                    }
                }
            })
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
