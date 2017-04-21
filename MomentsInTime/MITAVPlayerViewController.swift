//
//  MITAVPlayerViewController.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/21/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class MITAVPlayerViewController: AVPlayerViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        self.view.layoutIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
}
