//
//  TermsOfServiceController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/24/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

typealias TermsOfServiceSuccessCompletion = () -> Void

class TermsOfServiceController: WebViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let termsOfUseFileURL = MITDocuments.termsOfUse.localURL {
            self.loadLocalURL(url: termsOfUseFileURL)
        }
    }
}
