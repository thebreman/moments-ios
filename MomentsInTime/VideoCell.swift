//
//  VideoCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 3/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let SPACING_TITLE_SUBTITLE: CGFloat = 2.0

private let _sizingCell = Bundle.main.loadNibNamed(String(describing: VideoCell.self), owner: nil, options: nil)?.first as! VideoCell

class VideoCell: UICollectionViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var thumbnailImageView: CachedImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var subtitleTopContraint: NSLayoutConstraint!
    
    //collection of horizontal padding constraints:
    //container view horizontal padding and label horizontal padding
    //changes in storyboard will update these... 
    //we need to set preferredMaxLayoutWidth on the lables in flowLayout.sizeForItem...
    //the sum of these constraint's constants will be the necessary padding:
    @IBOutlet var horizontalPaddingConstraints: [NSLayoutConstraint]!
    
    var labelHorizontalPadding: CGFloat {
        var sum: CGFloat = 0
        self.horizontalPaddingConstraints.forEach { sum = $0.constant + sum }
        return sum
    }
    
    //collectionView flowLayout delegate will set this in sizeForItem...
    var preferredCellWidth: CGFloat? {
        didSet {
            if let width = self.preferredCellWidth {
                self.titleLabel.preferredMaxLayoutWidth = width - self.labelHorizontalPadding
                self.subtitleLabel.preferredMaxLayoutWidth = width - self.labelHorizontalPadding
            }
        }
    }
    
    var video: Video? {
        didSet {
            self.updateUI()
        }
    }
    
    class func sizeForVideo(_ video: Video, width: CGFloat) -> CGSize
    {
        let cell = _sizingCell
        
        cell.video = video
        cell.bounds = CGRect(x: 0, y: 0, width: width, height: 1000)
        
        //            cell.preferredCellWidth = collectionView.bounds.width
        
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let height = cell.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        print(height)
        
        let size =  CGSize(width: width, height: height)
        
        return size
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
