//
//  ContainerTableViewCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/28/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

class ContainerTableViewCell: UITableViewCell
{
    var containedView: UIView? {
        didSet {
            
            if self.contentView.subviews.count > 0 {
                self.contentView.subviews.forEach({ $0.removeFromSuperview() })
            }
            
            if let newView = self.containedView {
                self.contentView.addSubview(newView)
                newView.autoPinEdgesToSuperviewEdges()
                newView.autoCenterInSuperview()
                self.layoutIfNeeded()
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup()
    {
        self.backgroundColor = .clear
    }
}
