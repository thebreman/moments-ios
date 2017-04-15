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
    var view = UIView()
    
    class func sizeForCell(withWidth width: CGFloat) -> CGSize
    {
        let cell = _sizingCell
        cell.bounds = CGRect(x: 0, y: 0, width: width, height: 1000)
        
        // the system fitting does not honor the bounded width^ from above (it sizes the label as wide as possible)
        // we'll set a manual width constraint so we fully autolayout when asking for a fitted size:
        cell.contentView.removeConstraint(_sizingWidth)
        _sizingWidth = cell.contentView.autoSetDimension(ALDimension.width, toSize: width)
        
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let autoSize = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        let height = autoSize.height
        
        return CGSize(width: width, height: height)
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.setup()
    }
    
    private func setup()
    {
        self.contentView.addSubview(self.view)
        self.view.autoPinEdgesToSuperviewEdges()
    }
}
