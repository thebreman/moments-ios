//
//  MITSectionHeaderView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/17/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

class MITSectionHeaderView: UITableViewHeaderFooterView
{
    @IBOutlet weak var titleLabel: UILabel!
    
    var title: String?  {
        didSet {
            self.titleLabel.text = self.title
            self.contentView.layoutIfNeeded()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //setting th background color in IB has been deprecated
        //so we are required to do this:
        self.contentView.backgroundColor = UIColor.mitBackground
    }
}
