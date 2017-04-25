//
//  SpinnerCell.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/22/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import PureLayout

private let SPACING_TITLE_SUBTITLE: CGFloat = 2.0
private let _sizingCell = Bundle.main.loadNibNamed(String(describing: SpinnerCell.self), owner: nil, options: nil)?.first
private var _sizingWidth = NSLayoutConstraint()

class SpinnerCell: UICollectionViewCell
{
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    class func sizeForSpinnerCell(withWidth width: CGFloat) -> CGSize
    {
        if let cell = _sizingCell as? SpinnerCell {
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
        
        return .zero
    }
}
