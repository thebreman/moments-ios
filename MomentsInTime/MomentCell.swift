//
//  MomentCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

private let SPACING_TITLE_SUBTITLE: CGFloat = 2.0
private let SPACING_LABEL_MARGIN: CGFloat = 8.0
private let HEIGHT_UPLOAD_VIEW: CGFloat = 24.0

private let _sizingCell = Bundle.main.loadNibNamed(String(describing: MomentCell.self), owner: nil, options: nil)?.first
private var _sizingWidth = NSLayoutConstraint()

protocol MomentCellDelegate: class
{
    func momentCell(_ momentCell: MomentCell, playButtonWasTappedForMoment moment: Moment, sender: UIButton)
    func momentCell(_ momentCell: MomentCell, shareButtonWasTappedForMoment moment: Moment, sender: UIButton)
    func momentCell(_ momentCell: MomentCell, handleOptionsForMoment moment: Moment, sender: UIButton)
}

class MomentCell: BouncingCollectionViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var thumbnailImageView: CachedImageView!
    @IBOutlet weak var playButton: BouncingButton!
    @IBOutlet weak var shareButton: BouncingButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var subtitleTopContraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var uploadContainerView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var uploadContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var blinkingView: BlinkingView!
    
    weak var delegate: MomentCellDelegate?
    
    var moment: Moment? {
        didSet {
            self.updateUI()
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.isSelectable = false
        self.drawShadow()
        self.containerView.layer.masksToBounds = true
    }
    
    class func sizeForMoment(_ moment: Moment, width: CGFloat) -> CGSize
    {
        if let cell = _sizingCell as? MomentCell {
            cell.bounds = CGRect(x: 0, y: 0, width: width, height: 1000)
            cell.moment = moment
            
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
        if let moment = self.moment {
            self.delegate?.momentCell(self, playButtonWasTappedForMoment:moment, sender: sender)
        }
    }
    
    @IBAction func handleShare(_ sender: UIButton)
    {
        if let moment = self.moment {
            self.delegate?.momentCell(self, shareButtonWasTappedForMoment: moment, sender: sender)
        }
    }
    
    @IBAction func handleOptions(_ sender: UIButton)
    {
        if let moment = self.moment {
            self.delegate?.momentCell(self, handleOptionsForMoment: moment, sender: sender)
        }
    }
    
    // MARK: Utilities
    
    private func updateUI()
    {
        self.configureThumbnailImage()
        self.configureLabels()
        self.configureUploadingContainer()
        self.togglePlayButton()
        self.toggleShareButton()
    }
    
    private func configureUploadingContainer()
    {
        guard let status = self.moment?.momentStatus, status != .new else {
            self.uploadContainerHeightConstraint.constant = 0.0
            self.blinkingView.stopBlinking()
            return
        }

        self.uploadContainerHeightConstraint.constant = HEIGHT_UPLOAD_VIEW

        self.statusLabel.text = status.message
        self.statusLabel.textColor = status == .uploadFailed ? UIColor.mitRed : UIColor.gray
        
        if let statusColor = status.color {
            self.blinkingView.circleColor = statusColor
        }
        
        if status == .uploading {
            self.blinkingView.startBlinking()
        }
    }
    
    private func configureLabels()
    {
        // we could have only a title, no description
        // or neither, but we will never have a description and no title
        // so collapse the constraints accordingly:
        if let title = self.moment?.video?.name {
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
        if let description = self.moment?.video?.videoDescription {
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
        self.thumbnailImageView.contentMode = .scaleAspectFill
        
        //for vimeo thumbnail image urls:
        if let localImage = self.moment?.video?.localThumbnailImage {
            
            //for local images that have not been uploaded yet:
            self.thumbnailImageView.image = localImage
            return
        }
        else if let imageURLString = self.moment?.video?.thumbnailImageURL {
            self.thumbnailImageView.loadImageFromCache(withUrlString: imageURLString)
        }
        else {
            self.thumbnailImageView.image = #imageLiteral(resourceName: "interviewee_placeholder")
            self.thumbnailImageView.contentMode = .scaleAspectFit
        }
    }
    
    private func togglePlayButton()
    {
        if let video = self.moment?.video, video.isPlayable {
            self.playButton.isHidden = false
            return
        }
        
        self.playButton.isHidden = true
    }
    
    private func toggleShareButton()
    {
        guard let moment = self.moment else {
            self.shareButton.isHidden = false
            return
        }
        
        //only live moments and new ones (fetched from Vimeo) can be shared:
        //newly created local in progress Moments are saved and status is local not new...
        self.shareButton.isHidden = moment.momentStatus != .live && moment.momentStatus != .new
        
        // also, in-progress videos are allowed to share their video files..
        if moment.momentStatus == .local && moment.video?.localURL != nil
        {
            self.shareButton.isHidden = false
        }
    }
}
