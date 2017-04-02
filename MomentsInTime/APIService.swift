//
//  APIService.swift
//  VideoWonderland
//
//  Created by Andrew Ferrarone on 3/23/17.
//  Copyright © 2017 Andrew Ferrarone. All rights reserved.
//

import Alamofire

private let ACCESS_TOKEN_KEY = "Authorization"
private let ACCESS_TOKEN_VALUE = "Bearer c3867c80fcfb0b0c177f012d841fd1c3"
private let HOST = "https://api.vimeo.com"

//provide this header to let Vimeo know which API version we are working with
private let VERSION_ACCEPT_HEADER_KEY = "Accept"
private let VERSION_ACCEPT_HEADER_VALUE = "application/vnd.vimeo.*+json;version=3.2"

typealias BooleanResponseClosure = (_ success: Bool, _ error: Error?) -> Void
typealias UploadProgressClosure = (_ fractionCompleted: Double) -> Void
typealias VideoCompletion = ([Video]?, Error?) -> Void

class APIService: NSObject
{
    static let baseAPIEndpoint: String = HOST
    static let accessTokenKey: String = ACCESS_TOKEN_KEY
    static let accessTokenValue: String = ACCESS_TOKEN_VALUE
    static let versionAPIHeaderValue: String = VERSION_ACCEPT_HEADER_VALUE
    static let versionAPIHeaderKey: String = VERSION_ACCEPT_HEADER_KEY
    
    /**
     * Fetches all the videos in our feed:
     */
    func getVideosForCommunity(completion: @escaping VideoCompletion)
    {
        self.request(router: VideoRouter.all) { (response, error) in
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            if let result = response as? [String: Any], let data = result["data"] as? [[String: Any]] {
                
                let videos = self.videos(fromData: data)
                if videos.count == 0 {
                    print("No videos made it through something probably went wrong.")
                }
                
                completion(videos, nil)
                return
            }
            
            //catch all parsing errors:
            let error = NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
            completion(nil, error)
        }
    }
    
//MARK: Upload Videos
    
    /**
     * Upon successful upload, the uri of the new video will be passed along in the completion handler
     * But we will probably want to modify this, ideally we would return the newly created/ uploaded Video object here, so that client
     * can display it in HomeController in the completion handler, but since the video could still be processing, client should only display
     * videos with a status of "available"... so maybe the completion should just be a BooleanResponseClosure...
     */
    func create(video: Video, uploadProgress: @escaping UploadProgressClosure, completion: @escaping (String?, Error?) -> Void)
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
                
                //now that we have generated an upload ticket, we can stream an upload to Vimeo with a PUT request to uploadLink:
                self.upload(video: video, router: UploadRouter.create(ticketID: ticketID, uploadLink: uploadLink), uploadProgress: { fractionCompleted in
                    
                    uploadProgress(fractionCompleted)
                    
                }, completion: { (success, error) in
                    
                    if success {
                        
                        //upload was a success!, we must now complete the upload with a DELETE request to baseAPIEndpoint+completeURI:
                        print("upload success proceed with delete completURI")
                        self.completeUpload(router: UploadRouter.complete(completeURI: completeURI)) { (videoLocationURI, error) in
                            
                            guard error == nil else {
                                completion(nil, error)
                                return
                            }
                            
                            //Upload is now complete and we have the location URI, so we can add all the metaData:
                            video.uri = videoLocationURI
                            self.addMetadata(for: video)
                        }
                    }
                    else {
                        
                        //handle video upload failure:
                        print("upload error")
                        completion(nil, error)
                        return
                    }
                })
            }
            
            //catch all parsing error:
            let error = NSError(domain: "APIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Couldn't understand HTTP response"])
            completion(nil, error)
        }
    }
    
    /**
     * Streams and upload to Vimeo with a PUT request to the upload link provided by Vimeo with out ticket:
     * Calls client provided UploadProgressClosure periodically as the data is being uploaded.
     * completion handler indicates if the upload was a success or not and passes along an error if there was one:
     */
    private func upload(video: Video, router: URLRequestConvertible, uploadProgress: @escaping UploadProgressClosure, completion: @escaping BooleanResponseClosure)
    {
        if let localURL = video.localURL, let uploadURL = URL(string: localURL) {
            
            Alamofire.upload(uploadURL, with: router)
                
                .uploadProgress { progress in
                    uploadProgress(progress.fractionCompleted)
                }
                
                .validate(statusCode: [200])
                .response { response in
                    
                    if let uploadError = response.error {
                        print("upload error: \(uploadError)")
                        completion(false, uploadError)
                    }
                    else {
                        print("no upload error -> proceed")
                        completion(true, nil)
                    }
                }
        }
    }
    
    /**
     * Once video is successfully uploaded to Vimeo, we must complete the transaction with a DELETE request to host+completeURI
     * If all goes well, the response will contain a location header with the uri of the uploaded video as the value
     * client will have access to this in the completion hander String? param:
     */
    private func completeUpload(router: URLRequestConvertible, completion: @escaping (String?, Error?) -> Void)
    {
        Alamofire.request(router)
        
            .validate(statusCode: 200..<300)
            .response { response in
                
                if let error = response.error {
                    completion(nil, error)
                    return
                }
                
                if let location = response.response?.allHeaderFields["Location"] as? String {
                    completion(location, nil)
                    return
                }
                
                //catch all errors
                let error = NSError(domain: "APIService.completeUpload", code: 404, userInfo: [NSLocalizedDescriptionKey: "Couldn't complete upload: no location uri"])
                completion(nil, error)
            }
    }
    
    /**
     * Now that the upload dance is finally complete, we stil need to update the video w/ metadata: Title and description
     * We could upload a thumbnail image, but we will let Vimeo handle this for us, this code updates the video object with a PATCH request.
     * TODO: add completion handler...
     */
    private func addMetadata(for video: Video)
    {
        self.request(router: VideoRouter.update(video)) { (response, error) in
            
            guard error == nil else {
                print("error updating metadata: \(error)")
                return
            }
            
            //response will return updated Video Object w/ metadata, but since we just uploaded the video, it may still be processing 
            //and some fields may be null, such as thumbnail pictures, since they are being processed/ created...
            //there is a status field that will indicate if the video is available yet
            print(response ?? "no response")
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
 * Extension for Video parsing
 */
extension APIService
{
    func videos(fromData data: [[String: Any]]) -> [Video]
    {
        var videos = [Video]()
        
        for videoObject in data {
            if let video = Video.from(parameters: videoObject) {
                videos.append(video)
            }
        }
        
        return videos
    }
}
