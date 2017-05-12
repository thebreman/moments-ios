//
//  File.swift
//  MomentsInTime
//
//  Created by Brian on 5/11/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

private let FILE_DEFAULT_TOPICS = "default_topics"
private let DEFAULT_TOPICS_KEY_TOP = "topics"

class Topic
{
    var title : String = ""
    var description : String = ""
    
    convenience init(title: String, description: String)
    {
        self.init()
        
        self.title = title
        self.description = description
    }
    
    class func topicsFromJSON() -> [Topic]?
    {
        // grab the file url
        if let path = Bundle.main.path(forResource:FILE_DEFAULT_TOPICS, ofType: "json")
        {
            // file:// scheme is required
            let fullPath = "file://\(path)"
            
            // now actually grab the file
            if let pathURL = URL(string: fullPath)
            {
                // parse the file data as a json object
                if let jsonData = try? Data(contentsOf: pathURL),
                    let jsonResult = try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any]
                {
                    // grab the topics as an array of dictionaries
                    if let jsonTopics = jsonResult?[DEFAULT_TOPICS_KEY_TOP] as? [[String: String]]
                    {
                        // map the dictionary topic to actual Topics
                        let topics = jsonTopics.map({ (jsonTopic) -> Topic in
                            // grab the single key and value for each item to make a topic
                            let topic = Topic(title: Array(jsonTopic.keys)[0], description: Array(jsonTopic.values)[0])
                            return topic
                        })
                        
                        //success
                        return topics
                    }
                }
            }

        }
        
        // didn't make it
        
        print("Parsing default_topics.json failed")
        
        return nil
    }
}

