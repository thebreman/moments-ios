//
//  ContainerCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/15/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

/**
 * This is a cell that can optionally be displayed at the top of a UICollectionView (section 0).
 * It has an accessoryView:UIView property which will simply be displayed entirely in this cell.
 * This is great for UIViewControllers that need to display a message or ad to a user as the first item of the UICollectionView.
 * MITVideoCollectionViewAdapter has an optional accessoryView:UIView? property and when this is set, this cell will be displayed,
 * containing the view at the top of the collectionView in section 0, item 0...
 */

private let _sizingCell = ContainerCell()
private var _sizingWidth = NSLayoutConstraint()

class ContainerCell: UICollectionViewCell
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
    
    class func sizeForCell(withWidth width: CGFloat, containedView: UIView) -> CGSize
    {
        containedView.layoutIfNeeded()
        let size = CGSize(width: width, height: containedView.bounds.height)
        return size
    }
}
