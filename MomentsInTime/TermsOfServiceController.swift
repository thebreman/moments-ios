//
//  TermsOfServiceController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/24/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

typealias TermsOfServiceSuccessCompletion = () -> Void

class TermsOfServiceController: PDFViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.loadContent()
    }

    
    func loadContent()
    {
        if let termsOfUseFileURL = MITDocuments.termsOfUse.localURL {
            self.loadDocument(url: termsOfUseFileURL)
        }
    }
    
    deinit {
        print("DEINIT Terms Controller")
    }
}


