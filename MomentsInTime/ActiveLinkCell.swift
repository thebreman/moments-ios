//
//  ActiveLinkCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/17/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import ActiveLabel
import PureLayout

protocol ActiveLinkCellDelegate: class
{
    func activeLinkCell(_ activeLinkCell: ActiveLinkCell, handleSelection selection: String)
    func activeLinkCell(_ activeLinkCell: ActiveLinkCell, detailDisclosureButtonTapped sender: UIButton)
}

class ActiveLinkCell: UITableViewCell
{
    @IBOutlet weak var activeLabel: ActiveLabel!
    @IBOutlet weak var detailDisclosureButton: BouncingButton!
    @IBOutlet var activeLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var activeLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var activeLabelCenterXConstraint: NSLayoutConstraint!
    
    var shouldCenterLabel = false
    
    weak var delegate: ActiveLinkCellDelegate?
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.detailDisclosureButton.isHidden = true
    }
    
    var activeLinks: [String]? {
        didSet {
            if let links = self.activeLinks {
                
                //must batch-customize active label:
                self.activeLabel.customize { label in
                    
                    for link in links {
                        let customLinkType = ActiveType.custom(pattern: link)
                        label.customColor[customLinkType] = UIColor.mitActionblue
                        label.enabledTypes.append(customLinkType)
                        
                        label.handleCustomTap(for: customLinkType) { element in
                            self.delegate?.activeLinkCell(self, handleSelection: element)
                        }
                    }
                }
            }
            
            self.updateUI()
        }
    }
    
    private func updateUI()
    {
        self.activeLabelLeadingConstraint.isActive = self.shouldCenterLabel ? false : true
        self.activeLabelTrailingConstraint.isActive = self.shouldCenterLabel ? false : true
        self.activeLabelCenterXConstraint.isActive = self.shouldCenterLabel ? true : false
        self.activeLabel.needsUpdateConstraints()
    }
    
    //MARK: Actions
    
    @IBAction func handleDetailDisclosureTap(_ sender: BouncingButton)
    {
        self.delegate?.activeLinkCell(self, detailDisclosureButtonTapped: sender)
    }
}

