//
//  ImageTitleSubtitleCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 5/1/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let SPACING_NAME_ROLE: CGFloat = 2.0
private let SPACING_LEADING_IMAGE: CGFloat = 12.0
private let WIDTH_IMAGE: CGFloat = 64.0

class ImageTitleSubtitleCell: BouncingTableViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var roundImageView: MITCircleImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var subtitleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    
    var roundImage: UIImage? {
        didSet {
            self.roundImageView.image = self.roundImage
            self.updateUI()
        }
    }
    
    var imageURL: String? {
        didSet {
            if let imageURLString = self.imageURL {
                self.roundImageView.loadLocalImage(withUrl: imageURLString)
                self.updateUI()
            }
        }
    }
    
    var titleText: String? {
        didSet {
            self.titleLabel.text = self.titleText
            self.updateUI()
        }
    }
    
    var subtitleText: String? {
        didSet {
            self.subtitleLabel.text = self.subtitleText
            self.updateUI()
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.drawShadow()
        self.containerView.layer.masksToBounds = true
        self.isSelectable = false
    }
    
    private func updateUI()
    {
        self.configureProfileImage()
        self.configureLabels()
    }
    
    private func configureProfileImage()
    {
        if self.roundImageView.image != nil {
            self.imageViewWidthConstraint.constant = WIDTH_IMAGE
            self.imageViewHeightConstraint.constant = WIDTH_IMAGE
            self.imageViewLeadingConstraint.constant = SPACING_LEADING_IMAGE
        }
        else {
            
            //collapse the imageView and the leading space:
            self.imageViewWidthConstraint.constant = 0.0
            self.imageViewHeightConstraint.constant = 0.0
            self.imageViewLeadingConstraint.constant = 0.0
        }
    }
    
    private func configureLabels()
    {
        if let subText = self.subtitleLabel.text, subText.characters.count > 0 {
            self.subtitleLabelTopConstraint.constant = SPACING_NAME_ROLE
        }
        else {
            
            //collapse the space constraint b/w name and role:
            self.subtitleLabelTopConstraint.constant = 0.0
            self.subtitleLabel.text = nil
        }
    }
}

