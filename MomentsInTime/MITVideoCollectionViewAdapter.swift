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

private let SECTION_BANNER_TOP = 0
private let SECTION_VIDEO_FEED = 1
private let SECTION_VIDEO_FETCH = 2

//delegate for optional accessoryView to be displayed every nth cell (n is frequency):
protocol MITVideoCollectionViewAdapterDelegate: class
{
    func accessoryViewFrequency(forAdaptor adapter: MITVideoCollectionViewAdapter) -> Int
    func accessoryView(for adapter: MITVideoCollectionViewAdapter) -> UIView
}

//delegate to pass which video needs to be played after user taps playButton:
protocol MITVideoCollectionViewAdapterPlayerDelegate: class
{
    func adapter(adapter: MITVideoCollectionViewAdapter, handlePlayForVideo video: Video)
}

//delegate for fetch/ infinite scroll provides view to be displayed while fetching and handles fetching more content:
protocol MITVideoCollectionViewAdapterInfiniteScrollDelegate: class
{
    func fetchingView(for adapter: MITVideoCollectionViewAdapter) -> UIView
    
    //fetch new videos and call completion w/ those videos:
    func fetchNewVideos(for adapter: MITVideoCollectionViewAdapter, completion: @escaping ([Video]?) -> Void)
}

/**
 * Manages UICollectionViews throughout the app that display VideoCells...
 * The collectionViews are still responsible for loading and refreshing their content (VideoList),
 * but this class manages displaying the [Video].
 */
class MITVideoCollectionViewAdapter: NSObject, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, VideoCellDelegate
{
    private enum Identifiers
    {
        static let IDENTIFIER_REUSE_VIDEO_CELL = "videoCell"
        static let IDENTIFIER_REUSE_CONTAINER_CELL = "containerCell"
    }
    
    private var collectionView: UICollectionView!
    
    private weak var delegate: MITVideoCollectionViewAdapterDelegate?
    weak var playerDelegate: MITVideoCollectionViewAdapterPlayerDelegate?
    weak var infiniteScrollDelegate: MITVideoCollectionViewAdapterInfiniteScrollDelegate?
    
    var videos = [Video]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
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
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: String(describing: VideoCell.self), bundle: nil), forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_VIDEO_CELL)
        
        self.collectionView.emptyDataSetDelegate = self
        self.collectionView.emptyDataSetSource = self
    }
    
    private var videosAndAccessoryViews: [Any] {
        
        //instantiate array to hold both videos and accessoryViews:
        var videosAndAccessoryViews = [Any]()
        
        //if we have a delegate, setup the array with the corresponding data and return it:
        if let dataDelegate = self.delegate {
            
            let frequency = dataDelegate.accessoryViewFrequency(forAdaptor: self)
            
            //Go through self.videos, moving each object 1 by 1 into self.videosAndAccessoryViews,
            //append an accessoryView every nth index (n being frequency):
            for (index, video) in videos.enumerated() {
                
                videosAndAccessoryViews.append(video)
                
                if ((index % frequency) == (frequency - 1)) {
                    videosAndAccessoryViews.append(dataDelegate.accessoryView(for: self))
                }
            }
            
            return videosAndAccessoryViews
        }
        
        //if no delegate, then no accessory views so just return videos:
        return self.videos
    }
    
    //MARK: CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 3 //bannerCell, content, fetchCell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        switch section {
            
        case SECTION_BANNER_TOP:
            
            return self.bannerView != nil ? 1 : 0
        
        case SECTION_VIDEO_FEED:
            
            return self.videosAndAccessoryViews.count
            
        case SECTION_VIDEO_FETCH:
            
            return self.infiniteScrollDelegate != nil ? 1 : 0
        
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
            
            if let video = self.videosAndAccessoryViews[indexPath.item] as? Video {
                return self.videoCell(forVideo: video, atIndexPath: indexPath, withCollectionView: collectionView)
            }
            else if let accessoryView = self.videosAndAccessoryViews[indexPath.item] as? UIView {
                return self.containerCell(forView: accessoryView, atIndexPath: indexPath, withCollectionView: collectionView)
            }
            
            assert(false, "unknown object in dataSource")
            return UICollectionViewCell()
            
        case SECTION_VIDEO_FETCH:
            
            if let delegate = self.infiniteScrollDelegate {
                let view = delegate.fetchingView(for: self)
                return self.containerCell(forView: view, atIndexPath: indexPath, withCollectionView: collectionView)
            }
            
            return UICollectionViewCell()
            
        default:
            
            assert(false, "unknown section in collectionView!")
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        if indexPath.section == SECTION_VIDEO_FETCH {
            
            self.infiniteScrollDelegate?.fetchNewVideos(for: self) { newVideos in
                
                if let videosToDisplay = newVideos {
                    self.videos += videosToDisplay
                    self.collectionView.reloadData()
                    print(self.videos.count)
                }
            }
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
            
            if let video = self.videosAndAccessoryViews[indexPath.row] as? Video {
                return VideoCell.sizeForVideo(video, width: collectionView.bounds.width)
            }
            else if let accessoryView = self.videosAndAccessoryViews[indexPath.row] as? UIView {
                return ContainerCell.sizeForCell(withWidth: collectionView.bounds.width, containedView: accessoryView)
            }
            
            assert(false, "unknown object in dataSource")
            return .zero
            
        case SECTION_VIDEO_FETCH:
            
            if let delegate = self.infiniteScrollDelegate {
                let view = delegate.fetchingView(for: self)
                return ContainerCell.sizeForCell(withWidth: collectionView.bounds.width, containedView: view)
            }
            
            return .zero
            
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
    
    //MARK: VideoCellDelegate
    
    func videoCell(_ videoCell: VideoCell, playButtonWasTappedForVideo video: Video)
    {
        self.playerDelegate?.adapter(adapter: self, handlePlayForVideo: video)
    }
    
    //MARK: Utilities
    
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
            cell.delegate = self
            return cell
        }
        
        assert(false, "dequeued cell was of an unknown type!")
        return VideoCell()
    }
}

