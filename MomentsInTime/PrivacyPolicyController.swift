//
//  PrivacyPolicyController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 12/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class PrivacyPolicyController: PDFViewController
{    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.loadContent()
    }
    
    func loadContent()
    {
        if let privacyPolicyFileURL = MITDocuments.privacyPolicy.localURL {
            self.loadDocument(url: privacyPolicyFileURL)
        }
    }
    
    deinit {
        print("DEINIT privacy controller")
    }
}



