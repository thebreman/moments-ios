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
    var title: String?  {
        didSet {
            self.titleLabel.text = self.title
            self.contentView.layoutIfNeeded()
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.setup()
    }
    
    private func setup()
    {
        self.contentView.backgroundColor = UIColor.mitBackground
    }
}
