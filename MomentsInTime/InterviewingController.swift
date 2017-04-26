//
//  InterviewingController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/26/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class InterviewingController: UIViewController
{
    @IBOutlet weak var saveButton: BouncingButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.saveButton.isEnabled = false
    }
    
    //MARK: Actions
    
    @IBAction func handleSave(_ sender: BouncingButton)
    {
        print("save Interviewing info")
    }
    
    @IBAction func handleCancel(_ sender: BouncingButton)
    {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
