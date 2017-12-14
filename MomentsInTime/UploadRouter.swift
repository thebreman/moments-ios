//
//  UploadRouter.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Alamofire

private let ID_ALBUM_UPLOADED = "4630681"

enum UploadRouter: URLRequestConvertible
{
    case create(ticketID: String, uploadLink: String)
    case complete(completeURI: String)
    case addToUploadAlbum(Video)
    
    var method: Alamofire.HTTPMethod {
        switch self {
        case .create: return .put
        case .complete: return .delete
        case .addToUploadAlbum: return .put
        }
    }
    
    var path: String {
        switch self {
        case .create(ticketID: _, uploadLink: let link): return link
            
        //append completeURI onto baseAPIEndpoint.
        //Do not use url.appendPathComponent, b/c it will encode completeURI the wrong way:
        case .complete(completeURI: let uri): return VimeoConnector.baseAPIEndpoint + uri
        case .addToUploadAlbum(let video): return "/me/albums/\(ID_ALBUM_UPLOADED)\(video.uri ?? "")"
        }
    }
    
// MARK: URLRequestConvertible
    
    func asURLRequest() throws -> URLRequest
    {
        var url: URL
        var urlRequest: URLRequest
        
        switch self
        {
            case .create(ticketID: let ticketID, uploadLink: _):
                url = try self.path.asURL()
                urlRequest = URLRequest(url: url)
                urlRequest = try URLEncoding.httpBody.encode(urlRequest, with: ["ticket_id": ticketID])
            
            case .complete:
                url = try self.path.asURL()
                urlRequest = URLRequest(url: url)
            
            default:
                url = try VimeoConnector.baseAPIEndpoint.asURL()
                urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        }
        
        urlRequest.httpMethod = self.method.rawValue
        
        //JSON filter for improved rate limiting:
        urlRequest = try URLEncoding.queryString.encode(urlRequest, with: [FILTER_KEY: FILTER_VALUE_DEFAULT])
        
        //api version header and auth token header:
        urlRequest.setValue(VimeoConnector.versionAPIHeaderValue, forHTTPHeaderField: VimeoConnector.versionAPIHeaderKey)
        urlRequest.setValue(VimeoConnector.accessTokenValue, forHTTPHeaderField: VimeoConnector.accessTokenKey)
        
        print(urlRequest)
        return urlRequest
    }
}
