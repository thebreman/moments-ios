//
//  InterviewingSubjectCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/30/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

private let SPACING_NAME_ROLE: CGFloat = 2.0
private let SPACING_LEADING_IMAGE: CGFloat = 12.0
private let WIDTH_IMAGE: CGFloat = 64.0

class InterviewingSubjectCell: BouncingTableViewCell
{
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var profileImageView: MITCircleImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var roleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    
    var subject: Subject? {
        didSet {
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
        if let imageURLString = self.subject?.profileImageURL {
            self.profileImageView.loadImageFromDisk(withUrlString: imageURLString)
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
        self.nameLabel.text = self.subject?.name
        
        if let role = self.subject?.role {
            self.roleLabelTopConstraint.constant = SPACING_NAME_ROLE
            self.roleLabel.text = role
        }
        else {
            
            //collapse the space constraint b/w name and role:
            self.roleLabelTopConstraint.constant = 0.0
            self.roleLabel.text = nil
        }
    }
}

