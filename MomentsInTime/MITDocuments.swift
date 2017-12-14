//
//  MITDocuments.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 12/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import Foundation

private let FILE_PRIVACY_POLICY = "privacy_policy"
private let FILE_TERMS_OF_USE = "terms_of_use"

enum MITDocuments
{
    case privacyPolicy
    case termsOfUse
    
    var name: String {
        switch self
        {
            case .privacyPolicy: return FILE_PRIVACY_POLICY
            case .termsOfUse: return FILE_TERMS_OF_USE
        }
    }
    
    var fileExtension: String {
        return "docx"
    }
    
    var localURL: URL? {
        switch self
        {
            case .privacyPolicy:
                if let localPath = Bundle.main.path(forResource: self.name, ofType: self.fileExtension) {
                    let fullPath = "file://\(localPath)"
                    return URL(string: fullPath)
                }
            
            case .termsOfUse:
                if let localPath = Bundle.main.path(forResource: self.name, ofType: self.fileExtension) {
                    let fullPath = "file://\(localPath)"
                    return URL(string: fullPath)
                }
        }
        
        return nil
    }
}
