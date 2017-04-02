//
//  VideoCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class VideoCell: UICollectionViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var thumbnailImageView: CachedImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var video: Video? {
        didSet {
            self.updateUI()
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.drawShadow()
        self.containerView.layer.masksToBounds = true
        
        //content view is broken !? need this to make it work:
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func updateUI()
    {
        self.configureThumbnailImage()
        self.titleLabel.text = self.video?.name
        self.subtitleLabel.text = self.video?.videoDescription
    }
    
    private func configureThumbnailImage()
    {
        if let imageURLString = self.video?.thumbnailImageURL {
            self.thumbnailImageView.loadImageFromCache(withUrlString: imageURLString)
        }
    }

// MARK: Actions
    
    @IBAction func handleShare(_ sender: UIButton)
    {
        print("handle Share")
    }
    
    @IBAction func handleOptions(_ sender: UIButton)
    {
        print("handle Options")
    }
}
