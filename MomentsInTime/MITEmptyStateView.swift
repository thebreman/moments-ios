//
//  MITEmptyStateView.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/15/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit

class MITEmptyStateView: EmptyStateView
{
    override func setup()
    {
        super.setup()
        
        self.titleFont = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightSemibold)
        self.titleColor = UIColor.mitText
        
        self.messageFont = UIFont.systemFont(ofSize: 14.0)
        self.messageColor = UIColor.darkGray
        
        self.actionFont = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightSemibold)
        self.setActionColor(UIColor.mitActionblue, forState: .normal)
    }
    
    override var intrinsicContentSize: CGSize {
        if !(super.intrinsicContentSize.height > 0) {
            return CGSize(width: 100, height: 100)
        }
        return super.intrinsicContentSize
    }
}
