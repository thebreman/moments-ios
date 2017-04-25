//
//  FacebookConnector.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/24/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import FacebookCore
import FacebookLogin

private let VERSION_GRAPH_API = GraphAPIVersion(stringLiteral: "2.8")
private let PERMISSION_PUBLISH_ACTIONS = Permission(name: "publish_actions")

struct MyFeedPublishRequest: GraphRequestProtocol
{
    var graphPath: String = "/me/feed"
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .POST
    var apiVersion: GraphAPIVersion = VERSION_GRAPH_API
    
    //hardcoded for testing:
    var parameters: [String : Any]? = [
        "message": "check out my new video! @109978219553191",
        "link": "https://vimeo.com/200671449",
        "tags": "109978219553191",
        "place": "1320316014722478"
    ]
    
    struct Response: GraphResponseProtocol
    {
        init(rawResponse: Any?) {
            
            //Decode response JSON here:
            print("\n\(rawResponse ?? "nil response")")
        }
    }
}

struct MyFeedPostUpdateRequest: GraphRequestProtocol
{
    var graphPath: String = "/116049082275174_116397865573629"
    var accessToken: AccessToken? = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .POST
    var apiVersion: GraphAPIVersion = VERSION_GRAPH_API
    
    var parameters: [String : Any]? = ["tags": "MomentsInTimeATL"]
    
    struct Response: GraphResponseProtocol
    {
        init(rawResponse: Any?) {
            print(rawResponse ?? "nil reponse")
        }
    }
}

class FacebookConnector: NSObject
{
    func publishVideoToFacebook()
    {
        self.checkPermissions { granted, error in
            
            guard error == nil else {
                print(error!)
                return
            }
            
            if granted {
                self.publish()
            }
            else {
                print("publishing permission denied")
                //alert user that we need the permission and give them a button to reauthorize
                //or we just let them post to Vimeo only...
            }
        }
    }
    
    //doesnt seem to work. not sure if this is possible
    private func updatePost()
    {
        let connection = GraphRequestConnection()
        
        connection.add(MyFeedPostUpdateRequest()) { (response, result) in
            print(result)
        }
    }
    
    //If user denies Publishing permission, do we want to just post to Vimeo, or require Publishing permission?
    private func checkPermissions(completion: @escaping (Bool, Error?) -> Void)
    {
        guard let grantedPermissions = AccessToken.current?.grantedPermissions else {
            print("no granted permissions for current user - something went wrong")
            return
        }
        
        //check for publish_actions permission:
        if !grantedPermissions.contains(PERMISSION_PUBLISH_ACTIONS) {
            
            //ask for Publish Permissions:
            LoginManager().logIn([.publishActions], viewController: nil) { result in
                
                switch result {
                case .success(grantedPermissions: let granted, declinedPermissions: _, token: _):
                    completion(granted.contains(PERMISSION_PUBLISH_ACTIONS), nil)
                    
                case .failed(let error):
                    completion(false, error)
                    
                case .cancelled:
                    completion(false, nil)
                }
            }
        }
        else {
            
            //we have publishing permission so proceed:
            self.publish()
        }
    }
    
    private func publish()
    {
        let connection = GraphRequestConnection()
        
        connection.add(MyFeedPublishRequest()) { (response, result) in
            
            switch result {
                
            //success returns id of new post
            case .success(response: let response):
                print(response)
            case .failed(let error):
                print("Video Facebbok publish failed: \(error)")
            }
        }
        
        connection.start()
    }
}
