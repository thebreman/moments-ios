//
//  File.swift
//  MomentsInTime
//
//  Created by Brian on 5/11/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation
import RealmSwift

private let FILE_DEFAULT_TOPICS = "default_topics"
private let DEFAULT_TOPICS_KEY_TOP = "topics"

class Topic: Object
{
    @objc dynamic var title: String = ""
    @objc dynamic var topicDescription: String = ""
    @objc dynamic var isCustom: Bool = false
    
    convenience init(title: String, description: String)
    {
        self.init()
        
        self.title = title
        self.topicDescription = description
    }
    
    class func topicsFromJSON() -> [Topic]?
    {
        // grab the file url
        if let path = Bundle.main.path(forResource:FILE_DEFAULT_TOPICS, ofType: "json") {
            
            // file:// scheme is required
            let fullPath = "file://\(path)"
            
            if let pathURL = URL(string: fullPath) {
                
                // parse the file data as a json object
                if let jsonData = try? Data(contentsOf: pathURL),
                    let jsonResult = try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    
                    if let jsonTopics = jsonResult?[DEFAULT_TOPICS_KEY_TOP] as? [[String: String]] {
                        
                        // map the dictionary topic to actual Topics
                        let topics = jsonTopics.flatMap({ jsonTopic -> Topic in
                            let topic = Topic(title: Array(jsonTopic.keys)[0], description: Array(jsonTopic.values)[0])
                            return topic
                        })
                        
                        return topics
                    }
                }
            }
        }
        
        print("Parsing default_topics.json failed")
        return nil
    }
}

