//
//  MITVideoCollectionViewAdapter.swift
//  MomentsInTime
//
//  Created by Andrew Ferrarone on 4/14/17.
//  Copyright © 2017 Tikkun Olam. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

private let SECTION_BANNER_TOP = 0
private let SECTION_VIDEO_FEED = 1

//delegate for optional accessoryView to be displayed every nth cell (n is frequency):
protocol MITVideoCollectionViewAdapterDelegate: class
{
    func accessoryViewFrequency(forAdaptor adapter: MITVideoCollectionViewAdapter) -> Int
    func accessoryView(for adapter: MITVideoCollectionViewAdapter) -> UIView
}

/**
 * Manages UICollectionViews throughout the app that display VideoCells...
 * The collectionViews are still responsible for loading and refreshing their content (VideoList),
 * but this class manages displaying the [Video].
 */
class MITVideoCollectionViewAdapter: NSObject, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    private enum Identifiers
    {
        static let IDENTIFIER_REUSE_VIDEO_CELL = "videoCell"
        static let IDENTIFIER_REUSE_CONTAINER_CELL = "containerCell"
    }
    
    private var collectionView: UICollectionView!
    
    private weak var delegate: MITVideoCollectionViewAdapterDelegate?
    
    var videos = [Video]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    //if we have accessoryView, we will need an array of videos and accessoryViews:
    private var videosAndAccessoryViews: [Any]?
    
    private var emptyStateView = UIView()
    
    //optional top view that will be contained in a cell in section 0 at the top:
    //good for announcements, ads etc.
    //if it becomes necessary we could allow for an array of these views...
    private var bannerView: UIView?
    
    var allowsEmptyStateScrolling = false
    
    init(withCollectionView collectionView: UICollectionView, videos: [Video], emptyStateView: UIView, bannerView: UIView?, delegate: MITVideoCollectionViewAdapterDelegate?)
    {
        super.init()
        
        self.collectionView = collectionView
        self.videos = videos
        self.emptyStateView = emptyStateView
        self.bannerView = bannerView
        self.delegate = delegate
        
        if self.bannerView != nil || self.delegate != nil {
            self.collectionView.register(ContainerCell.self, forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL)
        }
        
        if self.delegate != nil {
            self.configureData()
        }
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: String(describing: VideoCell.self), bundle: nil), forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_VIDEO_CELL)
        
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
            
        case SECTION_BANNER_TOP:
            
            return self.bannerView != nil ? 1 : 0
        
        case SECTION_VIDEO_FEED:
            
            if let data = self.videosAndAccessoryViews {
                return data.count
            }
            
            return self.videos.count
        
        default:
            
            assert(false, "unknown section in collectionView!")
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        switch indexPath.section {
        
        case SECTION_BANNER_TOP:
            
            if let bannerView = self.bannerView {
                
                return self.containerCell(forView: bannerView, atIndexPath: indexPath, withCollectionView: collectionView)
            }
            
            return UICollectionViewCell()
        
        case SECTION_VIDEO_FEED:
            
            //check if we have videos and accessoryViews, then return the appropriate cell:
            if let data = self.videosAndAccessoryViews {
                
                if let video = data[indexPath.item] as? Video {
                    
                    return self.videoCell(forVideo: video, atIndexPath: indexPath, withCollectionView: collectionView)
                }
                else if let accessoryView = data[indexPath.item] as? UIView {
                    
                    return self.containerCell(forView: accessoryView, atIndexPath: indexPath, withCollectionView: collectionView)
                }
            }
            
            //otherwise return a video cell:
            let video = self.videos[indexPath.item]
            return self.videoCell(forVideo: video, atIndexPath: indexPath, withCollectionView: collectionView)
        
        default:
            
            assert(false, "unknown section in collectionView!")
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {        
        switch indexPath.section {
        
        case SECTION_BANNER_TOP:
            
            if let viewToDisplay = self.bannerView {
                let size = ContainerCell.sizeForCell(withWidth: collectionView.bounds.width, containedView: viewToDisplay)
                return size
            }
            
            return .zero
        
        case SECTION_VIDEO_FEED:
            
            if let data = self.videosAndAccessoryViews {
                
                if let video = data[indexPath.row] as? Video {
                    return VideoCell.sizeForVideo(video, width: collectionView.bounds.width)
                }
                else if let accessoryView = data[indexPath.row] as? UIView {
                    return ContainerCell.sizeForCell(withWidth: collectionView.bounds.width, containedView: accessoryView)
                }
            }
            
            let video = self.videos[indexPath.item]
            return VideoCell.sizeForVideo(video, width: collectionView.bounds.width)
        
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
        return self.allowsEmptyStateScrolling
    }
    
    //MARK: Utilities:
    
    private func configureData()
    {
        //instantiate array to hold both videos and accessoryViews:
        self.videosAndAccessoryViews = [Any]()
        
        if let dataDelegate = self.delegate {
            
            let frequency = dataDelegate.accessoryViewFrequency(forAdaptor: self)
            
            //Go through self.videos, moving each object 1 by 1 into self.videosAndAccessoryViews,
            //append an accessoryView every nth index (n being frequency):
            for (index, video) in videos.enumerated() {
                
                self.videosAndAccessoryViews?.append(video)

                if ((index % frequency) == (frequency - 1)) {
                    self.videosAndAccessoryViews?.append(dataDelegate.accessoryView(for: self))
                }
            }
        }
    }
    
    private func containerCell(forView view: UIView, atIndexPath indexPath: IndexPath, withCollectionView: UICollectionView) -> ContainerCell
    {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL, for: indexPath) as? ContainerCell {
            cell.containedView = view
            return cell
        }
        
        assert(false, "dequeued cell was of an unknown type!")
        return ContainerCell()
    }
    
    private func videoCell(forVideo video: Video, atIndexPath indexPath: IndexPath,  withCollectionView: UICollectionView) -> VideoCell
    {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_VIDEO_CELL, for: indexPath) as? VideoCell {
            cell.video = video
            return cell
        }
        
        assert(false, "dequeued cell was of an unknown type!")
        return VideoCell()
    }
}

