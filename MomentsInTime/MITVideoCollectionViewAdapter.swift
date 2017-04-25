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

fileprivate let videoCellHeightCache = NSCache<NSString, NSNumber>()

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
    //fetch new videos and call completion w/ those videos:
    func fetchNewVideos(for adapter: MITVideoCollectionViewAdapter, completion: @escaping () -> Void)
}

/**
 * Manages UICollectionViews throughout the app that display VideoCells...
 * The collectionViews are still responsible for loading and refreshing their content (VideoList),
 * but this class manages displaying the [Video].
 */
class MITVideoCollectionViewAdapter: NSObject, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, VideoCellDelegate
{
    var allowsEmptyStateScrolling = false
    var allowsInfiniteScrolling = false
    
    weak var accessoryViewdelegate: MITVideoCollectionViewAdapterDelegate? {
        didSet {
            self.collectionView.register(ContainerCell.self, forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL)
        }
    }
    
    weak var playerDelegate: MITVideoCollectionViewAdapterPlayerDelegate?
    
    weak var infiniteScrollDelegate: MITVideoCollectionViewAdapterInfiniteScrollDelegate? {
        didSet {
            self.collectionView.register(UINib(nibName: String(describing: SpinnerCell.self), bundle: nil), forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_SPINNER_CELL)
        }
    }
    
    var videos = [Video]() {
        didSet {
            self.refreshData()
        }
    }
    
    private enum Identifiers
    {
        static let IDENTIFIER_REUSE_VIDEO_CELL = "videoCell"
        static let IDENTIFIER_REUSE_CONTAINER_CELL = "containerCell"
        static let IDENTIFIER_REUSE_SPINNER_CELL = "spinnerCell"
    }
    
    private var collectionView: UICollectionView!
    
    private var videosAndAccessoryViews = [Any]()
    
    private var emptyStateView = UIView()
    
    //optional top view that will be contained in a cell in section 0 at the top:
    //good for announcements, ads etc.
    //if it becomes necessary we could allow for an array of these views...
    private var bannerView: UIView?
    
    init(withCollectionView collectionView: UICollectionView, videos: [Video], emptyStateView: UIView, bannerView: UIView?)
    {
        super.init()
        
        self.collectionView = collectionView
        self.videos = videos
        self.emptyStateView = emptyStateView
        self.bannerView = bannerView
        
        if self.bannerView != nil {
            self.collectionView.register(ContainerCell.self, forCellWithReuseIdentifier: Identifiers.IDENTIFIER_REUSE_CONTAINER_CELL)
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
        return 3 //bannerCell, content, fetchCell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        switch section {
            
        case SECTION_BANNER_TOP:
            let count = self.bannerView != nil ? 1 : 0
            return count
        
        case SECTION_VIDEO_FEED:
            return self.videosAndAccessoryViews.count
            
        case SECTION_VIDEO_FETCH:
            let count = self.infiniteScrollDelegate != nil && self.allowsInfiniteScrolling ? 1 : 0
            return count
            
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
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.IDENTIFIER_REUSE_SPINNER_CELL, for: indexPath) as? SpinnerCell {
                cell.spinner.startAnimating()
                cell.rasterizeShadow()
                return cell
            }
            
            assert(false, "dequeued cell was of an unknown type!")
            return UICollectionViewCell()
            
        default:
            
            assert(false, "unknown section in collectionView!")
            return UICollectionViewCell()
        }
    }
    
    private var fetching = false
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        guard !self.fetching else { return }
        
        if indexPath.section == SECTION_VIDEO_FETCH {
            
            self.fetching = true
            self.infiniteScrollDelegate?.fetchNewVideos(for: self) {
                if let spinnerCell = cell as? SpinnerCell {
                    spinnerCell.spinner.stopAnimating()
                    self.fetching = false
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
                
                var height = CGFloat(0)
                
                if let cachedHeight = videoCellHeightCache.object(forKey: video.uri as NSString) as? CGFloat {
                    height = cachedHeight
                }
                else {
                    let fittedSize = VideoCell.sizeForVideo(video, width: collectionView.bounds.width)
                    height = fittedSize.height
                    videoCellHeightCache.setObject(height as NSNumber, forKey: video.uri as NSString)
                }

                return CGSize(width: self.collectionView.bounds.width, height: height)
            }
            else if let accessoryView = self.videosAndAccessoryViews[indexPath.row] as? UIView {
                return ContainerCell.sizeForCell(withWidth: collectionView.bounds.width, containedView: accessoryView)
            }
            
            assert(false, "unknown object in dataSource")
            return .zero
            
        case SECTION_VIDEO_FETCH:
            
            let size = SpinnerCell.sizeForSpinnerCell(withWidth: collectionView.bounds.width)
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
        return self.allowsEmptyStateScrolling
    }
    
    //MARK: VideoCellDelegate
    
    func videoCell(_ videoCell: VideoCell, playButtonWasTappedForVideo video: Video)
    {
        self.playerDelegate?.adapter(adapter: self, handlePlayForVideo: video)
    }
    
    //MARK: Utilities
    
    private func refreshData()
    {
        print("refreshing Data")
        
        self.populateData()
        self.collectionView.reloadData()
    }
    
    private func populateData()
    {
        //instantiate array to hold both videos and accessoryViews:
        self.videosAndAccessoryViews = [Any]()
        
        //if we have a delegate, setup the array with the corresponding data and return it,
        //otherwise just copy self.videos:
        guard let dataDelegate = self.accessoryViewdelegate else {
            self.videosAndAccessoryViews = self.videos
            return
        }
        
        let frequency = dataDelegate.accessoryViewFrequency(forAdaptor: self)
        
        //Go through self.videos, moving each object 1 by 1 into self.videosAndAccessoryViews,
        //append an accessoryView every nth index (n being frequency):
        for (index, video) in videos.enumerated() {
            
            self.videosAndAccessoryViews.append(video)
            
            if (index % frequency) == (frequency - 1) {
                self.videosAndAccessoryViews.append(dataDelegate.accessoryView(for: self))
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
            cell.delegate = self
            return cell
        }
        
        assert(false, "dequeued cell was of an unknown type!")
        return VideoCell()
    }
}

