//
//  NewMomentController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/13/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class NewMomentController: UIViewController
{
    @IBOutlet weak var submitButton: BouncingButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.submitButton.isEnabled = false
    }
    
//MARK: Actions
    
    @IBAction func handleSubmit(_ sender: BouncingButton) {
    }
    
}
