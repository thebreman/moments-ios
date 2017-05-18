//
//  UploadRouter.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/5/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Alamofire

enum UploadRouter: URLRequestConvertible
{
    case create(ticketID: String, uploadLink: String)
    case complete(completeURI: String)
    
    var method: Alamofire.HTTPMethod {
        switch self {
        case .create: return .put
        case .complete: return .delete
        }
    }
    
    var path: String {
        switch self {
        case .create(ticketID: _, uploadLink: let link): return link
            
        //append completeURI onto baseAPIEndpoint.
        //Do not use url.appendPathComponent, b/c it will encode completeURI the wrong way:
        case .complete(completeURI: let uri): return VimeoConnector.baseAPIEndpoint + uri
        }
    }
    
// MARK: URLRequestConvertible
    
    func asURLRequest() throws -> URLRequest
    {
        var url: URL
        var urlRequest: URLRequest
        
        switch self {
        case .create(ticketID: let ticketID, uploadLink: _):
            url = try self.path.asURL()
            urlRequest = URLRequest(url: url)
            urlRequest = try URLEncoding.httpBody.encode(urlRequest, with: ["ticket_id": ticketID])
            urlRequest = try URLEncoding.queryString.encode(urlRequest, with: [FILTER_KEY: ""])
            
        case .complete:
            url = try self.path.asURL()
            urlRequest = URLRequest(url: url)
            urlRequest = try URLEncoding.queryString.encode(urlRequest, with: [FILTER_KEY: ""])
        }
        
        urlRequest.httpMethod = self.method.rawValue
        
        //api version header and auth token header:
        urlRequest.setValue(VimeoConnector.versionAPIHeaderValue, forHTTPHeaderField: VimeoConnector.versionAPIHeaderKey)
        urlRequest.setValue(VimeoConnector.accessTokenValue, forHTTPHeaderField: VimeoConnector.accessTokenKey)
        
        return urlRequest
    }
}
