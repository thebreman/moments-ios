//
//  VideoPreviewCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/1/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

protocol VideoPreviewCellDelegate: class
{
    func videoPreviewCell(_ videoPreviewCell: VideoPreviewCell, handlePlay video: Video)
    func videoPreviewCell(_ videoPreviewCell: VideoPreviewCell, handleOptions sender: BouncingButton)
}

class VideoPreviewCell: BouncingTableViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var playButton: BouncingButton!
    
    var video: Video? {
        didSet {
            self.videoImageView.image = self.video?.localThumbnailImage
            
            if self.videoImageView.image != nil {
                self.spinner.stopAnimating()
                self.playButton.isHidden = false
            }
        }
    }
    
    weak var delegate: VideoPreviewCellDelegate?
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.drawShadow()
        self.containerView.layer.masksToBounds = true
        self.isSelectable = false
        self.playButton.isHidden = true
        self.spinner.startAnimating()
    }
    
    //MARK: Actions
    
    @IBAction func handlePlay(_ sender: BouncingButton)
    {
        if let videoToPlay = self.video {
            self.delegate?.videoPreviewCell(self, handlePlay: videoToPlay)
        }
    }

    @IBAction func handleOptions(_ sender: BouncingButton)
    {
        self.delegate?.videoPreviewCell(self, handleOptions: sender)
    }
}
