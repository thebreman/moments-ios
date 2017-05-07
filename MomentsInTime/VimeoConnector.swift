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
private let ACESS_TOKEN_VALUE_PRODUCTION = "Bearer d63a52e30fff72f2fd868dfed35b318c"

private let HOST = "https://api.vimeo.com"

//provide this header to let Vimeo know which API version we are working with
private let VERSION_ACCEPT_HEADER_KEY = "Accept"
private let VERSION_ACCEPT_HEADER_VALUE = "application/vnd.vimeo.*+json;version=3.2"

typealias BooleanResponseClosure = (_ success: Bool, _ error: Error?) -> Void
typealias UploadProgressClosure = (_ fractionCompleted: Double) -> Void
typealias StringCompletionHandler = (String?, Error?) -> Void
typealias VideoCompletion = ([Video]?, Error?) -> Void

class VimeoConnector: NSObject
{
    static let baseAPIEndpoint: String = HOST
    static let accessTokenKey: String = ACCESS_TOKEN_KEY
    static let accessTokenValue: String = ACESS_TOKEN_VALUE_PRODUCTION
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
     * Upon successful upload, the uri of the new video will be passed along in the completion handler:
     */
    func create(video: Video, uploadProgress: @escaping UploadProgressClosure, completion: @escaping StringCompletionHandler)
    {
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
                self.upload(video: video, router: UploadRouter.create(ticketID: ticketID, uploadLink: uploadLink), uploadProgress: { fractionCompleted in
                    
                    uploadProgress(fractionCompleted)
                    
                }, uploadCompletion: completion) //pass along the completion
                
                return
            }
            
            //catch any errors:
            let error = NSError(domain: "VimeoConnector.create:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
            completion(nil, error)
        }
    }
    
    //MARK: Private
    
    /**
     * We cannot rely on completion/ response handlers to chain the necessary upload flow requests since we are background compatable.
     * We can only rely on the session delegate callbacks/ closures, and we can just pass along the upload completion handler
     * until the very end of the process, then call it...
     */
    private func upload(video: Video, router: URLRequestConvertible, uploadProgress: @escaping UploadProgressClosure, uploadCompletion: @escaping StringCompletionHandler)
    {
        //Create video file url:
        guard let localURL = video.localURL, let uploadURL = URL(string: localURL) else {
            let error = NSError(domain: "VimeoConnector.upload:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't create valid video file url"])
            uploadCompletion(nil, error)
            return
        }
        
        //configure delegate callbacks for the SessionManager:
        BackgroundUploadSessionManager.shared.delegate.taskDidSendBodyData = { session, sessionTask, bytesSentSinceLastTime, totalBytesSentSoFar, totalBytesExpectedToSend in
            
            let progress: Double = Double(totalBytesSentSoFar) / Double(totalBytesExpectedToSend)
            uploadProgress(progress)
        }
        
        BackgroundUploadSessionManager.shared.delegate.taskDidComplete = { session, task, error in
            
            guard error == nil else {
                print(error!)
                uploadCompletion(nil, error)
                return
            }
            
            //complete the upload:
            guard let completeURI = BackgroundUploadCompleteSessionManager.shared.completeURI else {
                let error = NSError(domain: "VimeoConnector.upload:", code: 400, userInfo: [NSLocalizedDescriptionKey: "No valid completeURI"])
                uploadCompletion(nil, error)
                return
            }
            
            self.completeUpload(video: video, router: UploadRouter.complete(completeURI: completeURI), uploadCompletion: uploadCompletion)
            
            //call system completion handler for this background task:
            BackgroundUploadSessionManager.shared.systemCompletionHandler?()
        }
        
        //start the task:
        BackgroundUploadSessionManager.shared.upload(uploadURL, with: router)
    }
    
    /**
     * Since completing the upload is part of the background compatable upload flow, we need to use a download task.
     * This works great b/c the response will be saved temporarily to disk, we can inspect/ grab the location header,
     * and add the video metadata, completing the upload flow...
     */
    private func completeUpload(video: Video, router: URLRequestConvertible, uploadCompletion: @escaping StringCompletionHandler)
    {
        //configure delegate callbacks for the SessionManager:
        BackgroundUploadCompleteSessionManager.shared.delegate.downloadTaskDidFinishDownloadingToURL = { session, task, url in
            
            guard let httpResponse = task.response as? HTTPURLResponse, let locationURI = httpResponse.allHeaderFields["Location"] as? String else {
                let error = NSError(domain: "VimeoConnector.completeUpload:", code: 400, userInfo: [NSLocalizedDescriptionKey: "Could not get location header"])
                uploadCompletion(nil, error)
                return
            }
            
            video.uri = locationURI
        }
        
        BackgroundUploadCompleteSessionManager.shared.delegate.taskDidComplete = { session, task, error in
            
            guard error == nil else {
                print(error!)
                uploadCompletion(nil, error)
                return
            }
            
            self.addMetadata(for: video, uploadCompletion: uploadCompletion)
            
            //call system completion handler for this background task:
            BackgroundUploadCompleteSessionManager.shared.systemCompletionHandler?()
        }
        
        //start the task:
        BackgroundUploadCompleteSessionManager.shared.download(router)
    }
    
    /**
     * again we will use a download task for this request so we can remain background compatable.
     * we can inspect/ parse the JSON newly uploaded Video object response in downloadTaskDidFinishDownloadingToURL:
     */
    private func addMetadata(for video: Video, uploadCompletion: @escaping StringCompletionHandler)
    {
        //configure delegate callbacks for the SessionManager:
        BackgroundUploadVideoMetadataSessionManager.shared.delegate.downloadTaskDidFinishDownloadingToURL = { session, task, url in
            
            print(task.response!)
            //response will contain JSON data of the newly created video object
            //it is probably still being processed by Vimeo, though so the thumbnail images will be null...
        }
        
        BackgroundUploadVideoMetadataSessionManager.shared.delegate.taskDidComplete = { session, task, error in
            
            guard error == nil else {
                print(error!)
                uploadCompletion(nil, error)
                return
            }
            
            //call system completion handler for this background task:
            BackgroundUploadVideoMetadataSessionManager.shared.systemCompletionHandler?()
        }
        
        //start the task:
        BackgroundUploadVideoMetadataSessionManager.shared.download(VideoRouter.update(video))
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
        
        print("selected video height: \(maxHeight)")
        return urlString
    }
}

