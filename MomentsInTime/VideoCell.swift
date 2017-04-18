//
//  VideoCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

private let SPACING_TITLE_SUBTITLE: CGFloat = 2.0

private let _sizingCell = Bundle.main.loadNibNamed(String(describing: VideoCell.self), owner: nil, options: nil)?.first
private var _sizingWidth = NSLayoutConstraint()

class VideoCell: UICollectionViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var thumbnailImageView: CachedImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var subtitleTopContraint: NSLayoutConstraint!

    var video: Video? {
        didSet {
            self.updateUI()
        }
    }
    
    class func sizeForVideo(_ video: Video, width: CGFloat) -> CGSize
    {
        if let cell = _sizingCell as? VideoCell {
            cell.bounds = CGRect(x: 0, y: 0, width: width, height: 1000)
            cell.video = video
            
            // the system fitting does not honor the bounded width^ from above (it sizes the label as wide as possible)
            // we'll set a manual width constraint so we fully autolayout when asking for a fitted size:
            cell.contentView.removeConstraint(_sizingWidth)
            _sizingWidth = cell.contentView.autoSetDimension(ALDimension.width, toSize: width)
            
            cell.setNeedsUpdateConstraints()
            cell.updateConstraintsIfNeeded()
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
            
            let autoSize = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
            let height = autoSize.height
            
            return CGSize(width: width, height: height)
        }
        
        return .zero
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.drawShadow()
        self.containerView.layer.masksToBounds = true
    }
    
    private func updateUI()
    {
        self.configureThumbnailImage()
        self.configureLabels()
    }
    
    private func configureLabels()
    {
        self.titleLabel.text = self.video?.name
        
        if let description = self.video?.videoDescription {
            self.subtitleTopContraint.constant = SPACING_TITLE_SUBTITLE
            self.subtitleLabel.text = description
        }
        else {
            
            //collapse the space constraint b/w title and subtitle:
            self.subtitleTopContraint.constant = 0.0
            self.subtitleLabel.text = nil
        }
    }
    
    private func configureThumbnailImage()
    {
        if let imageURLString = self.video?.thumbnailImageURL {
            self.thumbnailImageView.loadImageFromCache(withUrlString: imageURLString)
        }
    }

// MARK: Actions
    
    //might want to have this call a method, so that we could have the thumbnailImageView
    //recognize touches and call the same method. This way user can tap play or the image to play the video
    @IBAction func handlePlay(_ sender: UIButton)
    {
        if let videoTitle = self.titleLabel.text {
            print("play: \(videoTitle)")
        }
    }
    
    @IBAction func handleShare(_ sender: UIButton)
    {
        print("handle Share")
    }
    
    @IBAction func handleOptions(_ sender: UIButton)
    {
        print("handle Options")
    }
}
