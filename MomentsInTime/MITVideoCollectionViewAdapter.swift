//
//  MITVideoCollectionViewAdapter.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/14/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import PureLayout

/**
 * This is a cell that can optionally be displayed at the top of a UICollectionView (section 0).
 * It has an accessoryView:UIView property which will simply be displayed entirely in this cell.
 * This is great for UIViewControllers that need to display a message or ad to a user as the first item of the UICollectionView.
 * The Organizer has an optional accessoryView:UIView? property and when this is set, this cell will be displayed,
 * containing the view at the top of the collectionView in section 0, item 0...
 */

private let _sizingCell = Bundle.main.loadNibNamed(String(describing: AccessoryCell.self), owner: nil, options: nil)?.first as! AccessoryCell
private var _sizingWidth = NSLayoutConstraint()

class AccessoryCell: UICollectionViewCell
{
    var accessoryView = UIView()
    
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
        self.contentView.addSubview(self.accessoryView)
        self.accessoryView.autoPinEdgesToSuperviewEdges()
    }
}

/**
 * Manages UICollectionViews throughout the app that display VideoCells...
 * The collectionViews are still responsible for loading and refreshing their content (VideoList),
 * but this class manages displaying the [Video].
 */
class MITVideoCollectionViewAdapter: NSObject, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    private struct Identifiers {
        static let IDENTIFIER_REUSE_VIDEO_CELL = "videoCell"
        static let IDENTIFIER_REUSE_ACCESSORY_CELL = "accessoryCell"
        static let IDENTIFIER_NIB_VIDEO_CELL = "VideoCell"
    }
    
    var collectionView = UICollectionView()
    
    lazy var videos = [Video]()
    
    var emptyStateView = UIView()
    
    //optional top view that will be contained in a cell in section 0 at the top:
    //good for announcements etc...
    var accessoryView: UIView? {
        didSet {
            
            //setup collectionView to display an AccessoryCell at the top:
            self.collectionView.register(AccessoryCell.self, forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_ACCESSORY_CELL)
        }
    }
    
    init(withCollectionView collectionView: UICollectionView, videos: [Video], emptyStateView: UIView)
    {
        super.init()
        
        self.collectionView = collectionView
        self.videos = videos
        self.emptyStateView = emptyStateView
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: Identifiers.IDENTIFIER_NIB_VIDEO_CELL, bundle: nil), forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_VIDEO_CELL)
        
        self.collectionView.emptyDataSetDelegate = self
        self.collectionView.emptyDataSetSource = self
    }
    
    //MARK: CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        switch section {
        case 0:
            return self.accessoryView != nil ? 1 : 0
        case 1:
            return self.videos.count
        default:
            assert(false, "unknown section in collectionView!")
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        switch indexPath.section {
        
        case 0:
            
            if let accessoryView = self.accessoryView,
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_ACCESSORY_CELL, for: indexPath) as? AccessoryCell {
                cell.accessoryView = accessoryView
                return cell
            }
            
            assert(false, "dequeued cell was of an unknown type!")
            return AccessoryCell()
        
        case 1:
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_VIDEO_CELL, for: indexPath) as? VideoCell {
                cell.video = self.videos[indexPath.item]
                return cell
            }
            
            assert(false, "dequeued cell was of an unknown type!")
            return UICollectionViewCell()
        
        default:
            
            assert(false, "unknown section in collectionView!")
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        switch indexPath.section {
        
        case 0:
            
            let size = AccessoryCell.sizeForCell(withWidth: collectionView.bounds.width)
            return size
        
        case 1:
            
            let video = self.videos[indexPath.item]
            let size = VideoCell.sizeForVideo(video, width: collectionView.bounds.width)
            return size
        
        default:
            
            assert(false, "unknown section in collectionView!")
            return .zero
        }
    }
    
    //MARK: DZNEmptyDataSet
    
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView!
    {
        return self.emptyStateView
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool
    {
        return true
    }
}
