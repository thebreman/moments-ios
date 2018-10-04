//
//  PrivacyPolicyController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 12/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class PrivacyPolicyController: WebViewController
{    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        print("PrivacyPolicyController viewDidLoad")
        
        if let privacyPolicyFileURL = MITDocuments.privacyPolicy.localURL {
            self.loadLocalURL(url: privacyPolicyFileURL)
        }
    }
    
    deinit {
        print("DEINIT privacy controller")
    }
}



