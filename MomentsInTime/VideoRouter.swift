//
//  VideoRouter.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Alamofire

//for requests where we don't care about the response, we still need to use the json filter for rate limits:
let FILTER_KEY = "fields"
let QUERY_KEY = "query"
let SORT_KEY = "sort"

let FILTER_VALUE_DEFAULT = "uri"
private let FILTER_ALL_VIDEOS_VALUE = "uri,name,description,link,pictures.sizes,status"
private let FILTER_CREATE_VIDEO_VALUE = "ticket_id,upload_link_secure,complete_uri"
private let FILTER_READ_VIDEO_VALUE = "name,description,link,pictures,sizes,files,status"
private let FILTER_UPDATE_VIDEO_VALUE = "link"

private let PATH_VIDEOS = "/me/videos"

protocol VideoRouterCompliant
{
    static func from(parameters: [String: Any]) -> Video?
    func videoParameters() -> [String: Any]
}

enum VideoRouter: URLRequestConvertible
{
    case all(String) //pageURL
    case search(String)
    case create
    case read(Video)
    case update(Video)
    case destroy(Video)
    
    var method: Alamofire.HTTPMethod {
        switch self {
        case .all: return .get
        case .search: return .get
        case .create: return .post
        case .read: return .get
        case .update: return .patch
        case .destroy: return .delete
        }
    }
    
    var path: String {
        switch self {
        case .all(let pagePath): return pagePath
        case .search: return PATH_VIDEOS
        case .create: return PATH_VIDEOS
        case .read(let video): return video.uri ?? ""
        case .update(let video): return video.uri ?? ""
        case .destroy(let video): return video.uri ?? ""
        }
    }
    
// MARK: URLRequestConvertible
    
    func asURLRequest() throws -> URLRequest
    {
        let url = try VimeoConnector.baseAPIEndpoint.asURL()
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        //api version header and auth token header:
        urlRequest.setValue(VimeoConnector.versionAPIHeaderValue, forHTTPHeaderField: VimeoConnector.versionAPIHeaderKey)
        urlRequest.setValue(VimeoConnector.accessTokenValue, forHTTPHeaderField: VimeoConnector.accessTokenKey)
        
        //add any necessary params:
        //One way or another, EVERY request must use the JSON filter otherwise our rate limit is significantly dropped...
        //if we don't care about the response, we will just filter for the uri...
        switch self {
            
        case .all:
            let urlString = VimeoConnector.baseAPIEndpoint + self.path
            let url = try urlString.asURL()
            urlRequest.url = url
            urlRequest = try URLEncoding.queryString.encode(urlRequest, with: [FILTER_KEY: FILTER_ALL_VIDEOS_VALUE, SORT_KEY: "manual"])
            
        case .search(let query):
            //send along query and sort results by date:
            urlRequest = try URLEncoding.queryString.encode(urlRequest, with: [FILTER_KEY: FILTER_ALL_VIDEOS_VALUE, QUERY_KEY: query, SORT_KEY: "date"])
            
            
        case .read:
            urlRequest = try URLEncoding.queryString.encode(urlRequest, with: [FILTER_KEY: FILTER_READ_VIDEO_VALUE])
            
        case .create:
            urlRequest = try URLEncoding.queryString.encode(urlRequest, with: ["type": "streaming", FILTER_KEY: FILTER_CREATE_VIDEO_VALUE])
            
        case .update(let video):
            urlRequest = try URLEncoding.default.encode(urlRequest, with: video.videoParameters())
            urlRequest = try URLEncoding.queryString.encode(urlRequest, with: [FILTER_KEY: FILTER_UPDATE_VIDEO_VALUE])
            
        default:
            break
        }
        
        return urlRequest
    }
}
