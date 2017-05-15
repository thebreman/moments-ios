//
//  VimeoConnector.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Alamofire

private let ACCESS_TOKEN_KEY = "Authorization"
private let ACCESS_TOKEN_VALUE_STAGING = "Bearer aa145c1d9bb318d4ef2a459c732503bc"
private let ACCESS_TOKEN_VALUE_PRODUCTION = "Bearer 4bb6e9e2e0ecbdc0871a5f290bd1ed83"

private let HOST = "https://api.vimeo.com"

//provide this header to let Vimeo know which API version we are working with:
private let VERSION_ACCEPT_HEADER_KEY = "Accept"
private let VERSION_ACCEPT_HEADER_VALUE = "application/vnd.vimeo.*+json;version=3.2"

typealias BooleanResponseClosure = (_ success: Bool, _ error: Error?) -> Void
typealias UploadProgressClosure = (_ fractionCompleted: Double) -> Void
typealias StringCompletionHandler = (String?, Error?) -> Void
typealias UploadCompletion = (Moment?, Error?) -> Void
typealias VideoCompletion = ([Video]?, Error?) -> Void

class VimeoConnector: NSObject
{
    static let baseAPIEndpoint: String = HOST
    static let accessTokenKey: String = ACCESS_TOKEN_KEY
    static let accessTokenValue: String = ACCESS_TOKEN_VALUE_STAGING
    static let versionAPIHeaderValue: String = VERSION_ACCEPT_HEADER_VALUE
    static let versionAPIHeaderKey: String = VERSION_ACCEPT_HEADER_KEY
    
    /**
     * Fetches all the videos from our vimeo account (me/videos).
     * page is path to get videos from Vimeo API, in the response we update our static pagePath w/ the next page,
     * so that the next call can use this var to fetch the next page:
     */
    func getMomentsForCommunity(forPagePath pagePath: String, completion: @escaping MomentListCompletion)
    {
        self.request(router: VideoRouter.all(pagePath)) { (response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            if let result = response as? [String: Any],
                let paging = result["paging"] as? [String: Any],
                let data = result["data"] as? [[String: Any]] {
                
                let moments = self.moments(fromData: data)
                let nextPagePath = self.nextPagePath(fromPaging: paging)
                
                if moments.count == 0 {
                    print("No videos made it through - something probably went wrong.")
                }
                
                let momentList = MomentList(moments: moments, nextPagePath: nextPagePath)
                
                completion(momentList, nil)
                return
            }
            
            //catch all parsing errors:
            let error = NSError(domain: "VimeoConnector.getMomentsForCommunity:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
            completion(nil, error)
        }
    }
    
    /**
     * Wrapper for getVideosForCommunity:forPage:completion:, using VimeoConnector.initialPagePath as the first path to fetch:
     */
    func getCommunityMoments(forPagePath pagePath: String, completion: @escaping MomentListCompletion)
    {
        self.getMomentsForCommunity(forPagePath: pagePath, completion: completion)
    }
    
    /**
     * fetches a video from video uri, passes along name, and description in completion:
     */
    func getRemoteVideo(_ video: Video, completion: @escaping (Video?, Error?) -> Void)
    {
        self.request(router: VideoRouter.read(video)) { (response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            if let result = response as? [String: Any] {
                
                let fetchedVideo = Video()
                fetchedVideo.name = result["name"] as? String
                fetchedVideo.videoDescription = result["description"] as? String
                fetchedVideo.videoLink = result["link"] as? String

                completion(fetchedVideo, nil)
                return
            }
            
            //catch all parsing errors:
            let error = NSError(domain: "VimeoConnector.getRemoteVideo", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
            completion(nil, error)
        }
    }
    
    /**
     * Fetches playback urlString for specified Video, urlString passed along in the completion handler:
     * AuthToken must be for a Pro Account in order for the response to contain the correct fields...
     */
    func getPlaybackURL(forVideo video: Video, completion: @escaping StringCompletionHandler)
    {
        self.request(router: VideoRouter.read(video)) { (response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            if let result = response as? [String: Any], let files = result["files"] as? [[String: Any]] {
                
                if let playbackURLString = self.playbackURLString(fromFiles: files) {
                    completion(playbackURLString, nil)
                    return
                }
            }
            
            //catch all parsing errors:
            let error = NSError(domain: "VimeoConnector.getVideosForCommunity:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
            completion(nil, error)
        }
    }
    
    /**
     * Deletes a video from Vimeo, false and error if failed, true and nil if successful:
     */
    func delete(video: Video, completion: @escaping BooleanResponseClosure)
    {
        self.request(router: VideoRouter.destroy(video)) { (response, error) in
            
            guard error == nil else {
                completion(false, error)
                return
            }
            
            completion(true, nil)
            return
        }
    }
    
    /**
     * Upon successful upload, the new video will be populated with its new Vimeo URI and will be passed along in the completion handler:
     */
    func create(moment: Moment, uploadProgress: UploadProgressClosure?, completion: @escaping UploadCompletion)
    {
        self.checkForPendingUploads { alreadyUploading in
            
            guard alreadyUploading == false else {
                print("already uploading")
                let error = NSError(domain: "VimeoConnector.create", code: 400, userInfo: [NSLocalizedDescriptionKey: "Already uploading another video"])
                completion(nil, error)
                return
            }
            
            self.request(router: VideoRouter.create) { (response, error) in
                
                guard error == nil else {
                    completion(nil, error)
                    return
                }
                
                if let result = response as? [String: Any],
                    let ticketID = result["ticket_id"] as? String,
                    let uploadLink = result["upload_link_secure"] as? String,
                    let completeURI = result["complete_uri"] as? String {
                    
                    //pass along the complete URI to the sessionManager that will handle this request:
                    BackgroundUploadCompleteSessionManager.shared.completeURI = completeURI
                    
                    //now that we have generated an upload ticket, we can stream an upload to Vimeo with a PUT request to uploadLink:
                    BackgroundUploadSessionManager.shared.upload(moment: moment,
                                                                 router: UploadRouter.create(ticketID: ticketID, uploadLink: uploadLink),
                                                                 uploadCompletion: completion)
                    return
                }
                
                //catch any errors:
                let error = NSError(domain: "VimeoConnector.create:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
                completion(nil, error)
            }
        }
    }
    
    //true if there is an active upload already:
    func checkForPendingUploads(completion: @escaping (Bool) -> Void)
    {
        BackgroundUploadSessionManager.shared.session.getTasksWithCompletionHandler { (_, uploads, downloads) in
            if uploads.isEmpty && downloads.isEmpty {
                BackgroundUploadSessionManager.shared.moment = nil
                
                BackgroundUploadCompleteSessionManager.shared.session.getTasksWithCompletionHandler { (_, uploads, downloads) in
                    if uploads.isEmpty && downloads.isEmpty {
                        BackgroundUploadCompleteSessionManager.shared.moment = nil
                        
                        BackgroundUploadVideoMetadataSessionManager.shared.session.getTasksWithCompletionHandler { (_, uploads, downloads) in
                            if uploads.isEmpty && downloads.isEmpty {
                                BackgroundUploadVideoMetadataSessionManager.shared.moment = nil
                                completion(false)
                                return
                            }
                            else {
                                completion(true)
                                return
                            }
                        }
                    }
                    else {
                        completion(true)
                        return
                    }
                }
            }
            else {
                completion(true)
                return
            }
        }
    }
    
    // MARK: Utilities
    
    /**
     * request utitily function for requests with JSON responses:
     */
    private func request(router: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void)
    {
        let request = Alamofire.request(router)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                
                switch response.result {
                case .success(let value):
                    print(response.result)
                    completion(value, nil)
                    
                case .failure(let error):
                    print(error)
                    completion(nil, error)
                }
        }
        
        print(request)
    }
}


/**
 * Extension for Parsing:
 */
extension VimeoConnector
{
    fileprivate func moments(fromData data: [[String: Any]]) -> [Moment]
    {
        var moments = [Moment]()
        
        for videoObject in data {
            if let video = Video.from(parameters: videoObject) {
                let newMoment = Moment()
                newMoment.video = video
                moments.append(newMoment)
            }
        }
        
        return moments
    }
    
    fileprivate func nextPagePath(fromPaging paging: [String: Any]) -> String?
    {
        if let nextPage = paging["next"] as? String {
            return nextPage
        }
        
        return nil
    }
    
    fileprivate func playbackURLString(fromFiles files: [[String: Any]]) -> String?
    {
        var maxHeight = 0
        var urlString: String? = nil
        
        //loop through each Video file and select the highest quality one based on height:
        for file in files {
            
            if let videoHeight = file["height"] as? Int {
                
                if videoHeight > maxHeight {
                    maxHeight = videoHeight
                    urlString = file["link_secure"] as? String
                }
            }
        }
        
        return urlString
    }
}

