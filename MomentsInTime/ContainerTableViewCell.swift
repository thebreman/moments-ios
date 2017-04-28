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
    var containedView: UIView! {
        didSet {
            
            if self.contentView.subviews.count > 0 {
                self.contentView.subviews.forEach({ $0.removeFromSuperview() })
            }
            
            self.contentView.addSubview(self.containedView)
            self.containedView.autoPinEdgesToSuperviewEdges()
            self.layoutIfNeeded()
        }
    }
}
