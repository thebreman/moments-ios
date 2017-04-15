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
 * Manages UICollectionViews throughout the app that display VideoCells...
 * The collectionViews are still responsible for loading and refreshing their content (VideoList),
 * but this class manages displaying the [Video].
 */
class MITVideoCollectionViewAdapter: NSObject, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    private struct Identifiers {
        static let IDENTIFIER_REUSE_VIDEO_CELL = "videoCell"
        static let IDENTIFIER_REUSE_CONTAINER_CELL = "accessoryCell"
        static let IDENTIFIER_NIB_VIDEO_CELL = "VideoCell"
    }
    
    var collectionView: UICollectionView!
    
    var videos = [Video]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    var emptyStateView = UIView()
    
    //optional top view that will be contained in a cell in section 0 at the top:
    //good for announcements, ads etc.
    //if it becomes necessary we could allow for an array of these views...
    var accessoryView: UIView? {
        didSet {
            
            //setup collectionView to display an AccessoryCell at the top:
            if self.accessoryView != nil {
                self.collectionView.register(ContainerCell.self, forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL)
            }
        }
    }
    
    init(withCollectionView collectionView: UICollectionView, videos: [Video], emptyStateView: UIView, accessoryView: UIView?)
    {
        super.init()
        
        self.collectionView = collectionView
        self.videos = videos
        self.emptyStateView = emptyStateView
        self.accessoryView = accessoryView
        
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
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL, for: indexPath) as? ContainerCell {
                cell.view = accessoryView
                return cell
            }
            
            assert(false, "dequeued cell was of an unknown type!")
            return ContainerCell()
        
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
            
            let size = ContainerCell.sizeForCell(withWidth: collectionView.bounds.width)
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
