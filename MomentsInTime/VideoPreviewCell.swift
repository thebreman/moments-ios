//
//  VideoPreviewCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/1/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class VideoPreviewCell: BouncingTableViewCell
{
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var videoImageView: UIImageView!
    
    var videoImage: UIImage? {
        didSet {
            self.videoImageView.image = self.videoImage
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.drawShadow()
        self.containerView.layer.masksToBounds = true
        self.isSelectable = false
    }
    
    //MARK: Actions
    
    @IBAction func handlePlay(_ sender: BouncingButton)
    {
        print("handle play")
    }

    @IBAction func handleShare(_ sender: BouncingButton)
    {
        print("handle share")
    }
}
