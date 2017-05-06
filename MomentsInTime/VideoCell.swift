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
private let SPACING_LABEL_MARGIN: CGFloat = 8.0
private let _sizingCell = Bundle.main.loadNibNamed(String(describing: VideoCell.self), owner: nil, options: nil)?.first
private var _sizingWidth = NSLayoutConstraint()

protocol VideoCellDelegate: class
{
    func videoCell(_ videoCell: VideoCell, playButtonWasTappedForVideo video: Video)
    func videoCell(_ videoCell: VideoCell, shareButtonWasTappedForVideo video: Video)
}

class VideoCell: UICollectionViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var thumbnailImageView: CachedImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var subtitleTopContraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleBottomConstraint: NSLayoutConstraint!
    
    weak var delegate: VideoCellDelegate?
    
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

    // MARK: Actions
    
    @IBAction func handlePlay(_ sender: UIButton)
    {
        if let video = self.video {
            self.delegate?.videoCell(self, playButtonWasTappedForVideo: video)
        }
    }
    
    @IBAction func handleShare(_ sender: UIButton)
    {
        if let video = self.video {
            self.delegate?.videoCell(self, shareButtonWasTappedForVideo: video)
        }
    }
    
    @IBAction func handleOptions(_ sender: UIButton)
    {
        print("handle Options")
    }
    
    // MARK: Utilities
    
    private func updateUI()
    {
        self.configureThumbnailImage()
        self.configureLabels()
    }
    
    private func configureLabels()
    {
        // we could have only a title, no description
        // or neither, but we will never have a description and no title
        // so collapse the constraints accordingly:
        if let title = self.video?.name {
            self.titleTopConstraint.constant = SPACING_LABEL_MARGIN
            self.subtitleBottomConstraint.constant = SPACING_LABEL_MARGIN
            self.titleLabel.text = title
        }
        else {
            
            //collapse the title top constraint AND subtitle bottom:
            self.titleTopConstraint.constant = 0.0
            self.subtitleBottomConstraint.constant = 0.0
            self.titleLabel.text = nil
        }
        
        //if we dont have a description, then just collapse the middle space b/c we might have a title:
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
        //for vimeo thumbnail image urls:
        if let imageURLString = self.video?.thumbnailImageURL {
            self.thumbnailImageView.loadImageFromCache(withUrlString: imageURLString)
        }
        else if let localImage = self.video?.localThumbnailImage {
            
            //for local images that have not been uploaded yet:
            self.thumbnailImageView.image = localImage
        }
        else {
            self.thumbnailImageView.image = nil
        }
    }
}
